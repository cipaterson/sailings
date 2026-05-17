require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  # Roles bitmask tests

  test "new user has no roles by default" do
    user = User.new
    assert_equal [], user.roles
    assert_equal 0, user.roles_mask
  end

  test "assigns a single role" do
    user = User.new
    user.roles = [ "member" ]
    assert_equal [ "member" ], user.roles
  end

  test "assigns multiple roles" do
    user = User.new
    user.roles = [ "member", "trainer" ]
    assert_includes user.roles, "member"
    assert_includes user.roles, "trainer"
    assert_not_includes user.roles, "purser"
  end

  test "has_role? returns true for assigned role" do
    user = User.new(roles: [ "office_staff" ])
    assert user.has_role?("office_staff")
    assert_not user.has_role?("purser")
  end

  test "predicate methods reflect assigned roles" do
    user = User.new(roles: [ "crewing_operator", "purser" ])
    assert user.crewing_operator?
    assert user.purser?
    assert_not user.member?
    assert_not user.office_staff?
    assert_not user.trainer?
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
    user = User.new(roles: [ "member", "trainer" ])
    assert_not user.admin?
  end

  test "ignores unknown roles" do
    user = User.new
    user.roles = [ "member", "superuser" ]
    assert_equal [ "member" ], user.roles
  end

  test "roles= accepts empty array" do
    user = User.new(roles: [ "member", "trainer" ])
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
    user.update!(roles: [ "trainer" ])
    assert_includes User.with_role("trainer"), user
    assert_not_includes User.with_role("purser"), user
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
    user = User.new(password: "Ab1!")
    user.valid?
    assert_includes user.errors[:password].join, "at least 8 characters"
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

  test "password missing special character is invalid" do
    user = User.new(password: "NoSpecial1")
    user.valid?
    assert_includes user.errors[:password].join, "special"
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
