namespace :dev do
  desc "Seed test sailing records: past 30 days + next 60 days (PAST=n FUTURE=n to override counts)"
  task seed_sailings: :environment do
    past_count   = (ENV["PAST"]   || 15).to_i
    future_count = (ENV["FUTURE"] || 10).to_i

    past_count.times do
      departs = Faker::Time.between(from: 30.days.ago, to: 1.day.ago)
      FactoryBot.create(:sailing, departs_at: departs, returns_at: departs + rand(4..8).hours)
    end

    future_count.times do
      departs = Faker::Time.between(from: 1.day.from_now, to: 60.days.from_now)
      FactoryBot.create(:sailing, departs_at: departs, returns_at: departs + rand(4..8).hours)
    end

    puts "Created #{past_count} past and #{future_count} future sailings."
  end
end
