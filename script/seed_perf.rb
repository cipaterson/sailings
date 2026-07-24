# Generates a multi-year synthetic dataset for performance testing.
#
# Runs on a DEPLOYED server (staging), where the image is built with
# BUNDLE_WITHOUT="development:test" — so FactoryBot and Faker are NOT available
# and everything here is plain ActiveRecord plus stdlib.
#
# Invoked from a workstation without redeploying, by piping into rails runner:
#
#   ssh root@staging.firstsoftware.cc \
#     "docker exec -i -e SCALE=realistic -e WIPE=1 <container> bin/rails runner -" \
#     < script/seed_perf.rb
#
# Environment:
#   SCALE=realistic|stress   dataset size (default realistic)
#   YEARS=5                  how far back voyages start (default 5)
#   SEED=42                  RNG seed, so runs are reproducible
#   WIPE=1                   delete existing voyage data first (users are kept)
#
# Deliberately uses insert_all throughout. Besides being far faster than
# per-record saves on a 1-core box, it bypasses Sailing's validations — which
# matters because #no_unconfirmed_overlap rejects overlapping voyages and
# table-scans the (unindexed) departs_at column on every single save.

SCALE = ENV.fetch("SCALE", "realistic")
YEARS = ENV.fetch("YEARS", "5").to_i
WIPE  = ENV["WIPE"] == "1"
rng   = Random.new(ENV.fetch("SEED", "42").to_i)

TIERS = {
  "realistic" => { voyages: 1_500,  users: 250,   maintenance: 200   },
  "stress"    => { voyages: 15_000, users: 1_000, maintenance: 2_000 }
}
tier = TIERS.fetch(SCALE) { abort "SCALE must be one of: #{TIERS.keys.join(", ")}" }

BENCH_EMAIL    = "perfbench@example.com"
BENCH_PASSWORD = "Benchmark1"

now        = Time.current
window_min = now - YEARS.years
window_max = now + 6.months
span       = (window_max - window_min).to_i

FIRST_NAMES = %w[
  Alice Bruce Cathy David Eleanor Frank Grace Hamish Isla James Kate Liam Megan
  Nathan Olivia Peter Quinn Rachel Simon Tessa Ursula Victor Wendy Xavier Yvonne
  Zach Angus Bridie Callum Delia Ewan Fiona Gordon Heidi Ian Jasmine Keith Lucy
  Malcolm Nadia Owen Petra Roderick Sinead Tobias Una Vaughan Willa Yannick Zara
].freeze

LAST_NAMES = %w[
  Anderson Baxter Cameron Donnelly Eastwood Fletcher Gallagher Harrington Ingram
  Jamieson Kingsley Lockhart MacPherson Nicholson Ogilvie Patterson Quigley
  Robertson Sutherland Thompson Underwood Vandermeer Whitlock Yarwood Ziegler
  Ashcroft Blackwood Crawford Dunmore Ellsworth Fairbairn Grimshaw Hollingsworth
].freeze

PURPOSES = [
  "HS x2", "Sail and Walk", "Tasports Grant", "School Group",
  "SIT1", "SIT2", "Charter", "General Maintenance", "MSR Drill"
].freeze

MASTERS     = %w[PM RC AF DA CJ RH MW].freeze
LN_CONTACTS = %w[CJ JD Crewing PM].freeze

CHARTERERS = [
  "Hobart Grammar", "TasPorts", "Rotary Club", "Scouts Tasmania",
  "Sea Cadets", "Corporate Group", "Wooden Boat Festival", "JohnSmith"
].freeze

PROBLEMS = [
  "Capping rail near port stern has some rot",
  "Lizard on fore course port brace frayed",
  "Tear in bottom edge of Fisherman",
  "Starboard chainplate showing surface rust",
  "Bowsprit gammoning seized and needs reseizing",
  "Foremast stay chafing at spreader",
  "Bilge pump handle missing",
  "Compass light not working",
  "Navigation light (port) flickering",
  "Winch handle broken - stbd aft",
  "Deck leak above forward cabin bunk",
  "Galley fresh water pump losing prime",
  "Main halyard block seized",
  "Topsail sheet showing wear at cleat",
  "Fire extinguisher in engine room overdue for service",
  "Engine cooling water temp running high",
  "Anchor windlass gypsy slipping",
  "Heads seacock stiff to operate",
  "Flare kit expiry date passed",
  "Life ring bracket broken on port side"
].freeze

FIXED_NOTES = [
  "Replaced and tested.", "Repaired in situ.", "Parts ordered and fitted.",
  "Serviced by contractor.", "Cleaned and re-lubricated.", "No fault found on retest."
].freeze

MEMBERSHIPS = %w[Life Family Individual Junior].freeze
SKILL_COUNT = 10 # User::SKILLS.size

# Southern-hemisphere sailing season: busy over summer, quiet mid-winter.
MONTH_WEIGHTS = { 1 => 14, 2 => 13, 3 => 11, 4 => 8, 5 => 5, 6 => 3,
                  7 => 2,  8 => 3,  9 => 6, 10 => 9, 11 => 12, 12 => 14 }.freeze
WEIGHTED_MONTHS = MONTH_WEIGHTS.flat_map { |m, w| [ m ] * w }.freeze

def log(msg)
  puts "[seed_perf] #{msg}"
  $stdout.flush
end

# SQLite binds one parameter per column per row and refuses more than
# SQLITE_MAX_VARIABLE_NUMBER (32766) in a single statement. Size each batch from
# the actual column count so wide tables like sailings and users stay well under.
def bulk_insert(model, rows)
  return 0 if rows.empty?

  per_batch = [ 30_000 / rows.first.keys.size, 1 ].max
  rows.each_slice(per_batch) { |batch| model.insert_all(batch) }
  rows.size
end

log "scale=#{SCALE} years=#{YEARS} wipe=#{WIPE} env=#{Rails.env}"
log "target: #{tier[:voyages]} voyages, #{tier[:users]} users, #{tier[:maintenance]} maintenance tasks"

# Throwaway performance database — durability during the load is not worth the
# fsync cost on a single core.
ActiveRecord::Base.connection.execute("PRAGMA synchronous = OFF")

started = Time.current

if WIPE
  # Voyage-side data only. Existing user accounts are deliberately preserved so
  # nobody is locked out of staging; a few real rows alongside the synthetic
  # ones is noise at this scale.
  log "wiping voyage data (real user accounts preserved)..."
  SailingParticipant.delete_all
  Contact.where(contactable_type: "Sailing").delete_all
  Sailing.delete_all
  MaintenanceTask.delete_all

  # Synthetic members from previous runs must go too. insert_all skips rows that
  # violate the unique email index, so re-running with the same SEED would
  # otherwise silently keep the old (possibly larger) user set instead of
  # building the tier that was asked for.
  synthetic = User.where("email_address LIKE 'member%@example.com'")
  Contact.where(contactable_type: "User", contactable_id: synthetic.select(:id)).delete_all
  Session.where(user_id: synthetic.select(:id)).delete_all
  removed = synthetic.delete_all
  log "removed #{removed} synthetic members from previous runs"
end

# ---------------------------------------------------------------------- users

# BCrypt runs at production cost here (~250ms/hash). Hashing once and reusing
# the digest is the difference between seconds and many minutes for this step.
shared_digest = BCrypt::Password.create(BENCH_PASSWORD)

unless User.exists?(email_address: BENCH_EMAIL)
  User.insert_all([ {
    email_address: BENCH_EMAIL, password_digest: shared_digest,
    first_name: "Perf", last_name: "Bench",
    roles_mask: 15, skills_mask: 0, approved_at: now,
    membership_type: "Individual", created_at: now, updated_at: now
  } ])
  log "created benchmark account #{BENCH_EMAIL}"
end

user_rows = []
tier[:users].times do |i|
  joined = window_min + rng.rand(span).seconds

  # Most members hold only the base role; a handful carry admin roles.
  roles_mask = case rng.rand(100)
  when 0..84  then 1     # member
  when 85..93 then 1 | 2 # + office_staff
  when 94..97 then 1 | 4 # + crewing_operator
  else             1 | 8 # + maintenance
  end

  first = FIRST_NAMES[rng.rand(FIRST_NAMES.size)]
  last  = LAST_NAMES[rng.rand(LAST_NAMES.size)]

  # Qualification dates: a deliberate mix of current and long-expired, so
  # expiry-filtered views have realistic selectivity.
  issued  = joined + rng.rand(200).days
  expires = issued + (rng.rand(100) < 30 ? -rng.rand(400) : rng.rand(1200)).days

  user_rows << {
    email_address: "member#{i + 1}.#{last.downcase}@example.com",
    password_digest: shared_digest,
    first_name: first,
    last_name: last,
    birth_date: (now - (18 + rng.rand(60)).years).to_date,
    date_joined: joined.to_date,
    approved_at: rng.rand(100) < 96 ? joined : nil,
    membership_type: MEMBERSHIPS[rng.rand(MEMBERSHIPS.size)],
    roles_mask: roles_mask,
    skills_mask: rng.rand(2**SKILL_COUNT),
    days_sailed: rng.rand(300),
    fees_due: rng.rand(100) < 20 ? rng.rand(250) : 0,
    coxswain_issued_on: issued.to_date,
    coxswain_expires_on: expires.to_date,
    first_aid_issued_on: issued.to_date,
    first_aid_expires_on: expires.to_date,
    med_issued_on: issued.to_date,
    med_expires_on: expires.to_date,
    wwvp_issued_on: issued.to_date,
    wwvp_expires_on: expires.to_date,
    last_sailed: (joined + rng.rand(600).days).to_date,
    created_at: joined,
    updated_at: joined
  }
end

bulk_insert(User, user_rows)
user_rows = nil
log "users inserted (#{User.count} total)"

# [id, joined_at] pairs drive participant eligibility below — a member cannot
# crew a voyage that sailed before they joined. Sorted so the eligible set for
# a given date is always a prefix of the array.
members = User.where.not(date_joined: nil)
              .pluck(:id, :date_joined)
              .map { |id, d| [ id, d.to_time ] }
              .sort_by(&:last)
members = User.pluck(:id).map { |id| [ id, window_min ] } if members.empty?

# ------------------------------------------------------------- user contacts

user_ids_needing_contacts = User.where.not(email_address: BENCH_EMAIL)
                                .where.missing(:contact)
                                .pluck(:id, :first_name, :last_name, :email_address)

contact_rows = []
user_ids_needing_contacts.each do |id, fn, ln, email|
  next if rng.rand(100) < 25 # not everyone has a contact card on file

  contact_rows << {
    contactable_id: id, contactable_type: "User", contact_type: "contact",
    full_name: "#{fn} #{ln}", email_address: email,
    mobile: "04#{rng.rand(10**8).to_s.rjust(8, "0")}",
    address1: "#{rng.rand(300) + 1} Example Street",
    city: "Hobart", state: "Tasmania", postcode: "7000",
    created_at: now, updated_at: now
  }

  # Next of kin is a second polymorphic Contact row on the same user.
  next unless rng.rand(100) < 70
  contact_rows << {
    contactable_id: id, contactable_type: "User", contact_type: "next_of_kin",
    full_name: "#{FIRST_NAMES[rng.rand(FIRST_NAMES.size)]} #{ln}",
    email_address: "nok#{id}@example.com",
    mobile: "04#{rng.rand(10**8).to_s.rjust(8, "0")}",
    address1: "#{rng.rand(300) + 1} Example Street",
    city: "Hobart", state: "Tasmania", postcode: "7000",
    created_at: now, updated_at: now
  }
end

log "user contacts inserted (#{bulk_insert(Contact, contact_rows)} rows)"
contact_rows = nil

# -------------------------------------------------------------------- voyages

log "generating #{tier[:voyages]} voyages across #{YEARS} years..."

voyage_rows = []
generated   = 0

# Flushed periodically rather than accumulated: at the stress tier the full set
# of row hashes would be a large fraction of the free memory on this box.
while generated < tier[:voyages]
  # Seasonal weighting: pick a year uniformly, then a month by weight. Dates
  # that fall outside the window are simply redrawn, so the target count is met.
  year_offset = rng.rand(YEARS + 1)
  month       = WEIGHTED_MONTHS[rng.rand(WEIGHTED_MONTHS.size)]
  base        = window_min + year_offset.years
  day         = rng.rand(28) + 1
  departs = Time.zone.local(base.year, month, day, 7 + rng.rand(4), [ 0, 15, 30, 45 ][rng.rand(4)])
  next unless departs.between?(window_min, window_max)

  multiday = rng.rand(100) < 12
  returns  = multiday ? departs + (rng.rand(4) + 1).days + rng.rand(6).hours
                      : departs + (4 + rng.rand(5)).hours

  purpose = PURPOSES[rng.rand(PURPOSES.size)]

  sailing_type = case purpose
  when "SIT1", "SIT2"        then "Other"
  when "General Maintenance" then "Maintenance"
  else                            "Sail"
  end

  training = case purpose
  when "SIT1"      then "SIT1"
  when "SIT2"      then "SIT2"
  when "MSR Drill" then "MSR"
  end

  past = departs < now

  # ~5% are drafts, which by design carry no dates at all.
  draft = rng.rand(100) < 5

  status = if draft then "draft"
  elsif past        then rng.rand(100) < 80 ? "done" : "closed"
  else                   "scheduled"
  end

  charter = !draft && rng.rand(100) < 20
  quoted  = charter ? (rng.rand(40) + 10) * 10_000 : nil
  deposit = charter ? (quoted * 0.2).to_i : nil

  voyage_rows << {
    purpose: purpose,
    sailing_type: sailing_type,
    training: training,
    status: status,
    departs_at: draft ? nil : departs,
    returns_at: draft ? nil : returns,
    master: MASTERS[rng.rand(MASTERS.size)],
    ln_contact: LN_CONTACTS[rng.rand(LN_CONTACTS.size)],
    engineer: rng.rand(100) < 30 ? MASTERS[rng.rand(MASTERS.size)] : nil,
    passenger_count: 8 + rng.rand(18),
    charterer: charter ? CHARTERERS[rng.rand(CHARTERERS.size)] : nil,
    charter_state: charter ? (past ? "Paid" : [ "TBC", "Confirmed", "Outstanding" ][rng.rand(3)]) : "TBC",
    quoted_cost_cents: quoted,
    deposit_cents: deposit,
    final_amount_cents: charter && past ? quoted : nil,
    deposit_invoice: charter ? "DEP-#{rng.rand(90_000) + 10_000}" : nil,
    deposit_invoice_date: charter ? (departs - 30.days).to_date : nil,
    final_invoice: charter && past ? "INV-#{rng.rand(90_000) + 10_000}" : nil,
    invoice_date: charter && past ? (departs + 7.days).to_date : nil,
    date_paid: charter && past ? (departs + 21.days).to_date : nil,
    receipt_no: charter && past ? "R#{rng.rand(900_000) + 100_000}" : nil,
    comments: rng.rand(100) < 25 ? "Weather dependent. Confirm crew numbers the day before." : nil,
    additional_details: nil,
    created_at: departs - 60.days,
    updated_at: departs - 60.days
  }
  generated += 1

  if voyage_rows.size >= 2_000
    bulk_insert(Sailing, voyage_rows)
    voyage_rows = []
    log "  ...#{generated}/#{tier[:voyages]} voyages"
  end
end

bulk_insert(Sailing, voyage_rows)
log "voyages inserted (#{Sailing.count} total)"
voyage_rows = nil

# ---------------------------------------------------------- charter contacts

charter_contact_rows = []
Sailing.where.not(charterer: [ nil, "" ]).pluck(:id, :charterer, :created_at).each do |id, charterer, created|
  charter_contact_rows << {
    contactable_id: id, contactable_type: "Sailing", contact_type: "charter_contact",
    full_name: "#{FIRST_NAMES[rng.rand(FIRST_NAMES.size)]} #{LAST_NAMES[rng.rand(LAST_NAMES.size)]}",
    email_address: "bookings@#{charterer.downcase.gsub(/[^a-z]/, "")}.example.com",
    work_phone: "03#{rng.rand(10**8).to_s.rjust(8, "0")}",
    mobile: "04#{rng.rand(10**8).to_s.rjust(8, "0")}",
    address1: "#{rng.rand(300) + 1} Macquarie Street",
    city: "Hobart", state: "Tasmania", postcode: "70#{rng.rand(90) + 10}",
    created_at: created, updated_at: created
  }
end

log "charter contacts inserted (#{bulk_insert(Contact, charter_contact_rows)} rows)"
charter_contact_rows = nil

# --------------------------------------------------------------- participants

log "generating crew registrations..."

STATUSES = %w[registered confirmed standby cancelled].freeze
total_participants = 0

# Streamed in batches so the full participant set is never resident in memory —
# the box has well under 200 MB free.
Sailing.where.not(departs_at: nil)
       .pluck(:id, :departs_at, :created_at)
       .each_slice(500) do |slice|
  rows = []

  slice.each do |sailing_id, departs, created|
    eligible_count = members.bsearch_index { |(_, joined)| joined > departs } || members.size
    next if eligible_count < 6

    crew_size = 6 + rng.rand(7)
    crew_size = eligible_count if crew_size > eligible_count

    # Distinct member ids only — sailing_participants has a unique index on
    # [sailing_id, user_id].
    picked = {}
    attempts = 0
    while picked.size < crew_size && attempts < crew_size * 4
      picked[members[rng.rand(eligible_count)][0]] = true
      attempts += 1
    end

    past = departs < now

    picked.each_key do |user_id|
      status = if past then rng.rand(100) < 92 ? "confirmed" : "cancelled"
      else                  STATUSES[rng.rand(STATUSES.size)]
      end

      rows << {
        sailing_id: sailing_id, user_id: user_id,
        status: status,
        attended: past ? (status == "cancelled" ? 0 : 1) : nil,
        climbing: rng.rand(100) < 35 ? 1 : 0,
        comment: rng.rand(100) < 8 ? "Can only make the morning session." : nil,
        created_at: created, updated_at: created
      }
    end
  end

  total_participants += bulk_insert(SailingParticipant, rows)
end

log "participants inserted (#{total_participants} rows)"

# ---------------------------------------------------------- maintenance tasks

member_ids = members.map(&:first)
task_rows  = []

tier[:maintenance].times do
  reported = window_min + rng.rand(span).seconds
  closed   = rng.rand(100) < 70

  task_rows << {
    problem_description: PROBLEMS[rng.rand(PROBLEMS.size)],
    priority: %w[Low Medium High][rng.rand(3)],
    state: closed ? "Closed" : (rng.rand(100) < 50 ? "Reported" : "Open"),
    date_reported: reported,
    who_reported: member_ids[rng.rand(member_ids.size)].to_s,
    date_fixed: closed ? reported + rng.rand(90).days : nil,
    who_fixed: closed ? member_ids[rng.rand(member_ids.size)].to_s : nil,
    fixed_note: closed ? FIXED_NOTES[rng.rand(FIXED_NOTES.size)] : nil,
    comments: rng.rand(100) < 20 ? "Noticed during routine inspection." : nil,
    created_at: reported, updated_at: reported
  }
end

bulk_insert(MaintenanceTask, task_rows)
log "maintenance tasks inserted (#{MaintenanceTask.count} total)"

# ---------------------------------------------------------------------- done

ActiveRecord::Base.connection.execute("PRAGMA optimize")

elapsed = (Time.current - started).round(1)
log "-" * 60
log "completed in #{elapsed}s"
log "sailings=#{Sailing.count} users=#{User.count} participants=#{SailingParticipant.count} " \
    "contacts=#{Contact.count} maintenance=#{MaintenanceTask.count}"
log "voyage window: #{Sailing.minimum(:departs_at)} .. #{Sailing.maximum(:departs_at)}"
log "benchmark login: #{BENCH_EMAIL} / #{BENCH_PASSWORD}"
