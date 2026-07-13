require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "requires email_address" do
    user = User.new(email_address: "")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "can't be blank"
  end

  test "rejects a duplicate email_address" do
    user = User.new(email_address: users(:one).email_address, password: "ValidPass1")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "has already been taken"
  end

  test "rejects a duplicate email_address differing only in case" do
    user = User.new(email_address: "ONE@EXAMPLE.COM", password: "ValidPass1")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "has already been taken"
  end

  # Preferred home tests

  test "accepts a valid preferred_home key" do
    user = users(:one)
    user.preferred_home = "calendar"
    assert user.valid?
  end

  test "allows a blank preferred_home" do
    user = users(:one)
    user.preferred_home = ""
    assert user.valid?
  end

  test "rejects an unknown preferred_home key" do
    user = users(:one)
    user.preferred_home = "members"
    assert_not user.valid?
    assert_includes user.errors[:preferred_home], "is not included in the list"
  end

  # Approval tests

  test "approved? reflects approved_at presence" do
    assert users(:one).approved?
    assert_not users(:pending).approved?
  end

  test "pending and approved scopes partition users" do
    assert_includes User.pending, users(:pending)
    assert_not_includes User.pending, users(:one)
    assert_includes User.approved, users(:one)
    assert_not_includes User.approved, users(:pending)
  end

  # Roles bitmask tests

  test "new user has no roles by default" do
    user = User.new
    assert_equal [], user.roles
    assert_equal 0, user.roles_mask
  end

  test "defaults to member role on create when no roles set" do
    user = User.create!(email_address: "fresh@example.com", password: "ValidPass1")
    assert_equal [ "member" ], user.roles
  end

  test "keeps assigned roles on create instead of defaulting to member" do
    user = User.create!(email_address: "staff@example.com", password: "ValidPass1", roles: [ "office_staff" ])
    assert_equal [ "office_staff" ], user.roles
  end

  test "assigns a single role" do
    user = User.new
    user.roles = [ "member" ]
    assert_equal [ "member" ], user.roles
  end

  test "assigns multiple roles" do
    user = User.new
    user.roles = [ "member", "maintenance" ]
    assert_includes user.roles, "member"
    assert_includes user.roles, "maintenance"
    assert_not_includes user.roles, "office_staff"
  end

  test "has_role? returns true for assigned role" do
    user = User.new(roles: [ "office_staff" ])
    assert user.has_role?("office_staff")
    assert_not user.has_role?("maintenance")
  end

  test "predicate methods reflect assigned roles" do
    user = User.new(roles: [ "crewing_operator", "maintenance" ])
    assert user.crewing_operator?
    assert user.maintenance?
    assert_not user.member?
    assert_not user.office_staff?
  end

  test "admin? is true when office_staff" do
    user = User.new(roles: [ "office_staff" ])
    assert user.admin?
  end

  test "admin? is true when crewing_operator" do
    user = User.new(roles: [ "crewing_operator" ])
    assert user.admin?
  end

  test "admin? is false when neither office_staff nor crewing_operator" do
    user = User.new(roles: [ "member", "maintenance" ])
    assert_not user.admin?
  end

  test "ignores unknown roles" do
    user = User.new
    user.roles = [ "member", "superuser" ]
    assert_equal [ "member" ], user.roles
  end

  test "roles= accepts empty array" do
    user = User.new(roles: [ "member", "maintenance" ])
    user.roles = []
    assert_equal [], user.roles
    assert_equal 0, user.roles_mask
  end

  test "each role has a unique bitmask bit" do
    masks = User::ROLES.map { |r| User.new(roles: [ r ]).roles_mask }
    assert_equal masks.uniq, masks
  end

  test "with_role scope returns users with that role" do
    user = users(:one)
    user.update!(roles: [ "maintenance" ])
    assert_includes User.with_role("maintenance"), user
    assert_not_includes User.with_role("office_staff"), user
  end

  # Skills bitmask tests

  test "new user has no skills by default" do
    user = User.new
    assert_equal [], user.skills
    assert_equal 0, user.skills_mask
  end

  test "assigns a single skill" do
    user = User.new(skills: [ "deck" ])
    assert_equal [ "deck" ], user.skills
  end

  test "assigns skills across groups" do
    user = User.new(skills: [ "deck", "electrical", "historical" ])
    assert_includes user.skills, "deck"
    assert_includes user.skills, "electrical"
    assert_includes user.skills, "historical"
    assert_not_includes user.skills, "cook"
  end

  test "has_skill? returns true for assigned skill" do
    user = User.new(skills: [ "purser" ])
    assert user.has_skill?("purser")
    assert_not user.has_skill?("mechanical")
  end

  test "ignores unknown skills" do
    user = User.new
    user.skills = [ "deck", "flying" ]
    assert_equal [ "deck" ], user.skills
  end

  test "skills= accepts empty array" do
    user = User.new(skills: [ "deck", "cook" ])
    user.skills = []
    assert_equal [], user.skills
    assert_equal 0, user.skills_mask
  end

  test "each skill has a unique bitmask bit" do
    masks = User::SKILLS.map { |s| User.new(skills: [ s ]).skills_mask }
    assert_equal masks.uniq, masks
  end

  test "special_skills persists" do
    user = User.create!(email_address: "skilled@example.com", password: "ValidPass1",
                        skills: [ "deck" ], special_skills: "Diesel engine overhaul")
    assert_equal "Diesel engine overhaul", user.reload.special_skills
    assert_equal [ "deck" ], user.skills
  end

  # full_name

  test "full_name returns first and last name" do
    user = User.new(first_name: "Jane", last_name: "Doe")
    assert_equal "Jane Doe", user.full_name
  end

  test "full_name with only first name" do
    user = User.new(first_name: "Jane", last_name: nil)
    assert_equal "Jane", user.full_name
  end

  test "full_name with only last name" do
    user = User.new(first_name: nil, last_name: "Doe")
    assert_equal "Doe", user.full_name
  end

  test "full_name falls back to email_address when no name set" do
    user = User.new(email_address: "jane@example.com")
    assert_equal "jane@example.com", user.full_name
  end

  # membership_type validation

  test "valid membership types are accepted" do
    User::MEMBERSHIP_TYPES.each do |type|
      user = User.new(membership_type: type)
      user.valid?
      assert_empty user.errors[:membership_type], "Expected #{type} to be valid"
    end
  end

  test "invalid membership type is rejected" do
    user = User.new(membership_type: "Gold")
    user.valid?
    assert user.errors[:membership_type].any?
  end

  test "blank membership type is allowed" do
    user = User.new(membership_type: "")
    user.valid?
    assert_empty user.errors[:membership_type]
  end

  # password_complexity validation

  test "password too short is invalid" do
    user = User.new(password: "Ab1")
    user.valid?
    assert_includes user.errors[:password].join, "at least 6 characters"
  end

  test "password missing uppercase is invalid" do
    user = User.new(password: "alllower1!")
    user.valid?
    assert_includes user.errors[:password].join, "uppercase"
  end

  test "password missing lowercase is invalid" do
    user = User.new(password: "ALLUPPER1!")
    user.valid?
    assert_includes user.errors[:password].join, "lowercase"
  end

  test "password missing digit is invalid" do
    user = User.new(password: "NoDigits!")
    user.valid?
    assert_includes user.errors[:password].join, "digit"
  end

  test "password without a special character is valid" do
    user = User.new(password: "NoSpecial1")
    user.valid?
    assert_empty user.errors[:password]
  end

  test "six character password meeting other rules is valid" do
    user = User.new(password: "Abc12x")
    user.valid?
    assert_empty user.errors[:password]
  end

  test "password meeting all requirements is valid" do
    user = User.new(password: "ValidPass1!")
    user.valid?
    assert_empty user.errors[:password]
  end

  test "password complexity is skipped when password is not present" do
    user = users(:one)
    user.valid?
    complexity_keywords = %w[uppercase lowercase digit special characters]
    complexity_errors = user.errors[:password].select { |e| complexity_keywords.any? { |kw| e.include?(kw) } }
    assert_empty complexity_errors
  end
end
