# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
if ! User.find_by(email_address: "admin@example.com")
  User.create!(email_address: "admin@example.com", password: "Password123!", roles: [ :member, :office_staff, :crewing_operator, :maintenance ])
end
