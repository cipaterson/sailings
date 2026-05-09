# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
if ! User.find_by(email_address: "admin@example.com")
  User.create!(email_address: "admin@example.com", password: "Password123!", roles: [ :office_staff, :crewing_operator, :maintenance ])
end
if ! User.find_by(email_address: "office@example.com")
  User.create!(email_address: "office@example.com", password: "Password123!", roles: [ :office_staff ])
end
if ! User.find_by(email_address: "maintenance@example.com")
  User.create!(email_address: "maintenance@example.com", password: "Password123!", roles: [ :maintenance ])
end
if ! User.find_by(email_address: "crewing@ladynelson.org.au")
  User.create!(email_address: "crewing@ladynelson.org.au", password: "Password123!", roles: [ :crewing_operator ])
end
if ! User.find_by(email_address: "pleb@example.com")
  User.create!(email_address: "pleb@example.com", password: "Password123!", roles: [ :member ])
end

# require 'csv'
if Sailing.count < 10
  csv_text = File.read(Rails.root.join('lib', 'csvs', 'voyages.csv'))
  csv = CSV.parse(csv_text, headers: true, encoding: 'ISO-8859-1')
  csv.each do |row|
    Sailing.create!(purpose: row['Purpose'].presence || "blank", departs_date: row['Date'], departs_time: row['Time'],
      returns_date: row['Date Return'], returns_time: row['Time Return'], charterer: row['Charterer'],
      ln_contact: row['LN Contact'], master: row['Master'], passenger_count: row['No. of Passengers'],
      comments: row['Comments'])
  end
end

MaintenanceTask.find_or_create_by!(problem_description: "Capping rail near port stern has some rot") do |t|
  t.state = "Reported"
  t.priority = "Low"
  t.date_reported = Time.zone.parse("2026-04-12 14:44")
  t.date_fixed = Time.zone.parse("2026-04-13 16:52")
  t.who_reported = "4"
  t.who_fixed = "2"
  t.fixed_note = "Slapped in some epoxy bog"
end

MaintenanceTask.find_or_create_by!(problem_description: "Lizard on fore course port brace frayed") do |t|
  t.state = "Reported"
  t.priority = "Low"
  t.date_reported = Time.zone.parse("2026-04-13 16:07")
  t.date_fixed = Time.zone.parse("2026-04-15 16:46")
  t.who_reported = "2"
  t.who_fixed = "3"
  t.fixed_note = "Replaced lizard"
end

MaintenanceTask.find_or_create_by!(problem_description: "Tear in bottom edge of Fisherman") do |t|
  t.state = "Reported"
  t.priority = "High"
  t.date_reported = Time.zone.parse("2026-03-31 20:32")
  t.who_reported = "3"
end

MaintenanceTask.find_or_create_by!(problem_description: "Thing is wrong") do |t|
  t.state = "Reported"
  t.priority = "Low"
  t.date_reported = Time.zone.parse("2026-04-15 16:51")
  t.date_fixed = Time.zone.parse("2026-04-15 16:51")
  t.who_reported = "3"
  t.who_fixed = "3"
  t.fixed_note = "Thing fixed"
end

MaintenanceTask.find_or_create_by!(problem_description: "Out of tea, OMG!") do |t|
  t.state = "Reported"
  t.priority = "Low"
  t.date_reported = Time.zone.parse("2026-04-15 17:11")
  t.who_reported = "1"
end
MaintenanceTask.find_or_create_by!(problem_description: "1Capping rail near port stern has some rot") do |t|
  t.state = "Reported"
  t.priority = "Low"
  t.date_reported = Time.zone.parse("2026-04-12 14:44")
  t.date_fixed = Time.zone.parse("2026-04-13 16:52")
  t.who_reported = "4"
  t.who_fixed = "2"
  t.fixed_note = "Slapped in some epoxy bog"
end

MaintenanceTask.find_or_create_by!(problem_description: "1Lizard on fore course port brace frayed") do |t|
  t.state = "Reported"
  t.priority = "Low"
  t.date_reported = Time.zone.parse("2026-04-13 16:07")
  t.date_fixed = Time.zone.parse("2026-04-15 16:46")
  t.who_reported = "2"
  t.who_fixed = "3"
  t.fixed_note = "Replaced lizard"
end

MaintenanceTask.find_or_create_by!(problem_description: "1Tear in bottom edge of Fisherman") do |t|
  t.state = "Reported"
  t.priority = "High"
  t.date_reported = Time.zone.parse("2026-03-31 20:32")
  t.who_reported = "3"
end

MaintenanceTask.find_or_create_by!(problem_description: "1Thing is wrong") do |t|
  t.state = "Reported"
  t.priority = "Low"
  t.date_reported = Time.zone.parse("2026-04-15 16:51")
  t.date_fixed = Time.zone.parse("2026-04-15 16:51")
  t.who_reported = "3"
  t.who_fixed = "3"
  t.fixed_note = "Thing fixed"
end

MaintenanceTask.find_or_create_by!(problem_description: "1Out of tea, OMG!") do |t|
  t.state = "Reported"
  t.priority = "Low"
  t.date_reported = Time.zone.parse("2026-04-15 17:11")
  t.who_reported = "1"
end
MaintenanceTask.find_or_create_by!(problem_description: "2Capping rail near port stern has some rot") do |t|
  t.state = "Reported"
  t.priority = "Low"
  t.date_reported = Time.zone.parse("2026-04-12 14:44")
  t.date_fixed = Time.zone.parse("2026-04-13 16:52")
  t.who_reported = "4"
  t.who_fixed = "2"
  t.fixed_note = "Slapped in some epoxy bog"
end

MaintenanceTask.find_or_create_by!(problem_description: "2Lizard on fore course port brace frayed") do |t|
  t.state = "Reported"
  t.priority = "Low"
  t.date_reported = Time.zone.parse("2026-04-13 16:07")
  t.date_fixed = Time.zone.parse("2026-04-15 16:46")
  t.who_reported = "2"
  t.who_fixed = "3"
  t.fixed_note = "Replaced lizard"
end

MaintenanceTask.find_or_create_by!(problem_description: "2Tear in bottom edge of Fisherman") do |t|
  t.state = "Reported"
  t.priority = "High"
  t.date_reported = Time.zone.parse("2026-03-31 20:32")
  t.who_reported = "3"
end

MaintenanceTask.find_or_create_by!(problem_description: "2Thing is wrong") do |t|
  t.state = "Reported"
  t.priority = "Low"
  t.date_reported = Time.zone.parse("2026-04-15 16:51")
  t.date_fixed = Time.zone.parse("2026-04-15 16:51")
  t.who_reported = "3"
  t.who_fixed = "3"
  t.fixed_note = "Thing fixed"
end

MaintenanceTask.find_or_create_by!(problem_description: "2Out of tea, OMG!") do |t|
  t.state = "Reported"
  t.priority = "Low"
  t.date_reported = Time.zone.parse("2026-04-15 17:11")
  t.who_reported = "1"
end
