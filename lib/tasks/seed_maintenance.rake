namespace :dev do
  desc "Seed 40 maintenance task records (10 in progress, 30 closed)"
  task seed_maintenance: :environment do
    user_ids = User.pluck(:id).map(&:to_s)
    user_ids = ["1"] if user_ids.empty?

    fixed_notes = [
      "Treated with epoxy and repainted",
      "Replaced with new line",
      "Repaired with sailmaker's adhesive",
      "Cleaned and regreased",
      "Replaced fitting",
      "Tightened and re-seized",
      "New part sourced and fitted",
      "Temporary repair — monitor closely",
      "Serviced by contractor",
      "Fixed by crew during maintenance day"
    ]

    10.times do
      FactoryBot.create(:maintenance_task,
        state: ["Reported", "Open"].sample,
        who_reported: user_ids.sample)
    end

    30.times do
      reported_at = Faker::Time.between(from: 90.days.ago, to: 30.days.ago)
      fixed_at    = Faker::Time.between(from: reported_at + 1.day, to: reported_at + 21.days)

      FactoryBot.create(:maintenance_task,
        state:         "Closed",
        date_reported: reported_at,
        who_reported:  user_ids.sample,
        date_fixed:    fixed_at,
        who_fixed:     user_ids.sample,
        fixed_note:    fixed_notes.sample)
    end

    puts "Created 10 in-progress and 30 closed maintenance tasks."
  end
end
