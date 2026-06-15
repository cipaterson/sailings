namespace :dev do
  desc "Seed test users"
  task seed_test_users: :environment do
    common = {
      membership_type: "Individual",
      fees_due: 2026,
    }

    people = [
      {
        email_address: "member@zzyplza.com",
        password: "Passwo1",
        roles: [ :member ],
        first_name: "Sam", last_name: "Mariner",
        sailing_class: "T",
        fees_paid: Date.new(2025, 6, 28),
        marine_safety_refresher_on: Date.new(2025, 8, 12)
      },
      {
        email_address: "cipaterson@proton.me",
        password: "Passwo1",
        roles: [ :member, :crewing_operator, :maintenance ],
        first_name: "Chris", last_name: "Paterson",
        sailing_class: "S",
        fees_paid: Date.new(2025, 6, 25),
        ess_qualification: "SMT",
        ess_issued_on: Date.new(2023, 3, 15),
        ess_expires_on: Date.new(2028, 3, 15),
        wwvp_qualification: "Registered",
        wwvp_issued_on: Date.new(2023, 6, 30),
        wwvp_expires_on: Date.new(2027, 6, 30),
        marine_safety_refresher_on: Date.new(2025, 9, 15)
      },
      {
        email_address: "admin@zzyplza.com",
        password: "Passwo1",
        roles: [ :member, :office_staff, :crewing_operator, :maintenance ],
        first_name: "Alex", last_name: "Harbour",
        sailing_class: "M",
        fees_paid: Date.new(2025, 7, 12),
        ess_qualification: "Cert  12977",
        ess_issued_on: Date.new(2023, 3, 15),
        ess_expires_on: Date.new(2028, 3, 15),
        med_qualification: "MED 3",
        med_issued_on: Date.new(2022, 11, 2),
        med_expires_on: Date.new(2027, 11, 2),
        wwvp_qualification: "Registered",
        wwvp_issued_on: Date.new(2023, 6, 30),
        wwvp_expires_on: Date.new(2027, 6, 30),
        marine_safety_refresher_on: Date.new(2025, 7, 20)
      }
    ]

    people.each do |attrs|
      attrs    = attrs.dup
      password = attrs.delete(:password)
      roles    = attrs.delete(:roles)
      email    = attrs.delete(:email_address)

      user = User.find_or_initialize_by(email_address: email)
      user.password = password if user.new_record?
      user.assign_attributes(common.merge(attrs))
      user.roles = roles
      user.contact ||= user.build_contact(contact_type: "contact")
      ## user.contact.mobile = "0402220609"
      user.save!
    end

    puts "Seeded #{people.size} test users."
  end
end
