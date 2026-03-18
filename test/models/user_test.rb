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
end
