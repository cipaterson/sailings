require "csv"

namespace :members do
  desc "Import members from tmp/members.csv into the users table"
  task import: :environment do
    csv_path = Rails.root.join("tmp", "members.csv")
    abort "File not found: #{csv_path}" unless File.exist?(csv_path)

    created = 0
    updated = 0
    errors  = 0

    CSV.foreach(csv_path, headers: true) do |row|
      email = row["Email"].to_s.strip.downcase
      next if email.blank?

      ActiveRecord::Base.transaction do
        user = User.find_or_initialize_by(email_address: email)
        is_new = user.new_record?

        user.first_name       = row["First name"].presence
        user.last_name        = row["Surname"].presence
        user.occupation       = row["Occupation"].presence
        user.membership_type  = row["Member Type"].presence
        user.birth_date       = parse_member_date(row["Birth Date"])
        user.date_joined      = parse_member_date(row["Date Joined"])
        user.fees_due         = row["Fees Due"].to_s.strip.to_i.nonzero?
        user.fees_paid        = parse_member_date(row["Fees Paid"])
        user.knots_on                   = parse_member_date(row["Knots"])
        user.marine_safety_refresher_on = parse_member_date(row["Marine Safety Refresher"])
        user.last_sailed                = parse_member_date(row["Last Sailed"])
        user.first_aid_qualification    = row["First Aid"].presence
        user.ess_qualification          = row["E.S.S."].presence
        user.med_qualification          = row["M.E.C."].presence
        user.coxswain_qualification     = row["Coxswain Cert"].presence
        user.wwvp_qualification         = row["Working with Children"].presence
        user.food_handling_qualification = row["Food Handling"].presence

        roles = row["Roles"].to_s.split(",").map { |r| r.strip.gsub(" ", "_").downcase }
        user.roles = roles & User::ROLES

        user.password = (SecureRandom.alphanumeric(12) + "Aa1!").chars.shuffle.join if is_new

        user.save!

        contact = user.contact || user.build_contact(contact_type: "contact")
        contact.full_name  = "#{user.first_name} #{user.last_name}".strip.presence
        contact.mobile     = row["Phone (mobile)"].presence
        contact.work_phone = row["Phone (home)"].presence
        contact.postcode   = row["Postcode"].presence
        contact.save!

        is_new ? created += 1 : updated += 1
      rescue ActiveRecord::RecordInvalid => e
        errors += 1
        puts "  ERROR row #{$.} (#{email}): #{e.message}"
        raise ActiveRecord::Rollback
      end
    rescue StandardError => e
      errors += 1
      puts "  ERROR row #{$.}: #{e.message}"
    end

    puts "\nDone — created: #{created}, updated: #{updated}, errors: #{errors}"
  end
end

def parse_member_date(val)
  return nil if val.blank?
  val = val.strip
  return Date.new(val.to_i, 6, 30) if val.match?(/\A\d{4}\z/)
  Date.strptime(val, "%d/%m/%Y")
rescue Date::Error
  Date.parse(val)
rescue Date::Error
  nil
end
