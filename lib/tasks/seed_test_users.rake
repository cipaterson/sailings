namespace :dev do
  desc "Seed test users"
  task seed_test_users: :environment do
    if ! User.find_by(email_address: "admin@example.com")
      User.create!(email_address: "admin@example.com", password: "Password123!", roles: [ :member, :office_staff, :crewing_operator, :maintenance ])
    end
    if ! User.find_by(email_address: "cipaterson@proton.me")
      User.create!(email_address: "cipaterson@proton.me", password: "Passwo1!", roles: [ :member, :office_staff, :crewing_operator, :maintenance ])
    end
    if ! User.find_by(email_address: "cipaterson@gmail.com")
      User.create!(email_address: "cipaterson@gmail.com", password: "Passwo1!", roles: [ :member, :office_staff, :crewing_operator, :maintenance ])
    end
    if ! User.find_by(email_address: "ewa8ygv@proton.me")
      User.create!(email_address: "ewa8ygv@proton.me", password: "Passwo1!", roles: [ :member, :office_staff, :crewing_operator, :maintenance ])
    end

    puts "Created 4 users, if they were missing."
  end
end
