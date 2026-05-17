require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  # --- Authentication ---

  test "unauthenticated user cannot access index" do
    get users_path
    assert_redirected_to new_session_path
  end

  # --- Authorization: index/new/create/destroy require office_staff ---

  test "member cannot access users index" do
    sign_in_as users(:member)
    get users_path
    assert_redirected_to root_path
  end

  test "crewing_operator cannot access users index" do
    sign_in_as users(:crewing_operator)
    get users_path
    assert_redirected_to root_path
  end

  test "office_staff can access users index" do
    sign_in_as users(:office_staff)
    get users_path
    assert_response :success
  end

  test "member cannot create a user" do
    sign_in_as users(:member)
    post users_path, params: { user: { email_address: "new@example.com", password: "ValidPass1!" } }
    assert_redirected_to root_path
  end

  test "member cannot destroy a user" do
    sign_in_as users(:member)
    delete user_path(users(:two))
    assert_redirected_to root_path
  end

  # --- Authorization: show/edit/update require self or office_staff ---

  test "user can view their own profile" do
    sign_in_as users(:member)
    get user_path(users(:member))
    assert_response :success
  end

  test "user cannot view another user's profile" do
    sign_in_as users(:member)
    get user_path(users(:two))
    assert_redirected_to root_path
  end

  test "office_staff can view any user's profile" do
    sign_in_as users(:office_staff)
    get user_path(users(:member))
    assert_response :success
  end

  test "user can edit their own profile" do
    sign_in_as users(:member)
    get edit_user_path(users(:member))
    assert_response :success
  end

  test "user cannot edit another user's profile" do
    sign_in_as users(:member)
    get edit_user_path(users(:two))
    assert_redirected_to root_path
  end

  test "office_staff can edit any user's profile" do
    sign_in_as users(:office_staff)
    get edit_user_path(users(:member))
    assert_response :success
  end

  # --- index filtering ---

  test "index filters by role" do
    sign_in_as users(:office_staff)
    get users_path, params: { roles: [ "crewing_operator" ] }
    assert_response :success
  end

  test "index ignores unknown roles in filter" do
    sign_in_as users(:office_staff)
    get users_path, params: { roles: [ "superuser" ] }
    assert_response :success
  end

  test "index searches by name" do
    sign_in_as users(:office_staff)
    get users_path, params: { search: "member" }
    assert_response :success
  end

  # --- create ---

  test "office_staff can create a user" do
    sign_in_as users(:office_staff)
    assert_difference "User.count", 1 do
      post users_path, params: { user: {
        email_address: "newuser@example.com",
        password: "ValidPass1!",
        password_confirmation: "ValidPass1!"
      } }
    end
    assert_redirected_to user_path(User.last)
  end

  test "create with invalid params re-renders new" do
    sign_in_as users(:office_staff)
    assert_no_difference "User.count" do
      post users_path, params: { user: { email_address: "newuser@example.com", password: "weak" } }
    end
    assert_response :unprocessable_entity
  end

  # --- update ---

  test "user can update their own profile" do
    sign_in_as users(:member)
    patch user_path(users(:member)), params: { user: { first_name: "Updated" } }
    assert_redirected_to users_path
    assert_equal "Updated", users(:member).reload.first_name
  end

  test "update with blank password does not change password_digest" do
    sign_in_as users(:office_staff)
    original_digest = users(:member).password_digest
    patch user_path(users(:member)), params: { user: { first_name: "Jane", password: "", password_confirmation: "" } }
    assert_redirected_to users_path
    assert_equal original_digest, users(:member).reload.password_digest
  end

  test "update with invalid params re-renders edit" do
    sign_in_as users(:office_staff)
    patch user_path(users(:member)), params: { user: { password: "weak" } }
    assert_response :unprocessable_entity
  end

  # --- destroy ---

  test "office_staff can destroy a user" do
    sign_in_as users(:office_staff)
    assert_difference "User.count", -1 do
      delete user_path(users(:two))
    end
    assert_redirected_to users_path
  end
end
