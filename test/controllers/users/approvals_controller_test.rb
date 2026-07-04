require "test_helper"

class Users::ApprovalsControllerTest < ActionDispatch::IntegrationTest
  setup { @pending = users(:pending) }

  test "unauthenticated user cannot approve" do
    post user_approval_path(@pending)
    assert_redirected_to new_session_path
    assert_not @pending.reload.approved?
  end

  test "member cannot approve" do
    sign_in_as users(:member)
    post user_approval_path(@pending)
    assert_redirected_to root_path
    assert_not @pending.reload.approved?
  end

  test "office_staff cannot approve before payment is confirmed" do
    sign_in_as users(:office_staff)
    @pending.update_columns(fees_paid: nil, membership_type: "Individual")

    post user_approval_path(@pending)

    assert_redirected_to edit_user_path(@pending, tab: "membership")
    assert_not @pending.reload.approved?
  end

  test "office_staff cannot approve without a membership type" do
    sign_in_as users(:office_staff)
    @pending.update_columns(fees_paid: Date.current, membership_type: nil)

    post user_approval_path(@pending)

    assert_redirected_to edit_user_path(@pending, tab: "membership")
    assert_not @pending.reload.approved?
  end

  test "office_staff approves once payment and membership type are set" do
    sign_in_as users(:office_staff)
    @pending.update_columns(fees_paid: Date.current, membership_type: "Individual")

    post user_approval_path(@pending)

    assert_redirected_to users_path(pending: true)
    assert @pending.reload.approved?
    assert_includes @pending.roles, "member"
  end

  test "approving an already-approved user is a no-op with notice" do
    sign_in_as users(:office_staff)
    already = users(:member)

    assert_no_changes -> { already.reload.approved_at } do
      post user_approval_path(already)
    end
    assert_redirected_to users_path(pending: true)
  end
end
