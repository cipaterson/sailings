# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
if ! User.find_by(email_address: "admin@example.com")
  User.create!(email_address: "admin@example.com", password: "Password123!", roles: [:office_staff, :crewing_operator])
end
if ! User.find_by(email_address: "office@example.com")
  User.create!(email_address: "office@example.com", password: "Password123!", roles: [:office_staff])
end
if ! User.find_by(email_address: "crewing@ladynelson.org.au")
  User.create!(email_address: "crewing@ladynelson.org.au", password: "Password123!", roles: [:crewing_operator])
end
if ! User.find_by(email_address: "pleb@example.com")
  User.create!(email_address: "pleb@example.com", password: "Password123!", roles: [:member])
end

# require 'csv'
if Sailing.count < 10
  csv_text = File.read(Rails.root.join('lib', 'csvs', 'voyages.csv'))
  csv = CSV.parse(csv_text, headers: true, encoding: 'ISO-8859-1')
  csv.each do |row|
    Sailing.create!(purpose: row['Purpose'].presence || "blank", departs_date: row['Date'], departs_time: row['Time'],
      returns_date: row['Date Return'], returns_time: row['Time Return'], charterer: row['Charterer'],
      ln_contact: row['LN Contact'], master: row['Master'], passenger_count: row['No. of Passengers'],
      comments: row['Comments'],
      status: "draft")
  end
end
