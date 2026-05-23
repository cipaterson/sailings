require "test_helper"

class SailingParticipantsControllerTest < ActionDispatch::IntegrationTest
  # --- index (requires office_staff or crewing_operator) ---

  test "unauthenticated user cannot view participants" do
    get sailing_sailing_participants_path(sailings(:multiday))
    assert_redirected_to new_session_path
  end

  test "member cannot view participants index" do
    sign_in_as users(:member)
    get sailing_sailing_participants_path(sailings(:multiday))
    assert_redirected_to root_path
  end

  test "office_staff can view participants index" do
    sign_in_as users(:office_staff)
    get sailing_sailing_participants_path(sailings(:multiday))
    assert_response :success
  end

  test "crewing_operator can view participants index" do
    sign_in_as users(:crewing_operator)
    get sailing_sailing_participants_path(sailings(:multiday))
    assert_response :success
  end

  # --- create (self-registration) ---

  test "member can register themselves for a sailing" do
    sign_in_as users(:member)
    assert_difference "SailingParticipant.count", 1 do
      post sailing_sailing_participants_path(sailings(:multiday)),
           params: { sailing_participant: { status: "EOI" } }
    end
    assert_redirected_to sailings_path
    participant = SailingParticipant.last
    assert_equal users(:member).id, participant.user_id
  end

  test "member can register with a comment" do
    sign_in_as users(:member)
    assert_difference "SailingParticipant.count", 1 do
      post sailing_sailing_participants_path(sailings(:multiday)),
           params: { sailing_participant: { status: "EOI", comment: "my comment" } }
    end
    assert_redirected_to sailings_path
    assert_equal "my comment", SailingParticipant.last.comment
  end

  test "member cannot register another user" do
    sign_in_as users(:member)
    assert_no_difference "SailingParticipant.count" do
      post sailing_sailing_participants_path(sailings(:multiday)),
           params: { sailing_participant: { user_id: users(:two).id, status: "EOI" } }
    end
    assert_redirected_to root_path
  end

  test "office_staff can register another user" do
    sign_in_as users(:office_staff)
    assert_difference "SailingParticipant.count", 1 do
      post sailing_sailing_participants_path(sailings(:multiday)),
           params: { sailing_participant: { user_id: users(:member).id, status: "EOI" } }
    end
    assert_redirected_to sailing_sailing_participants_path(sailings(:multiday))
  end

  test "duplicate registration fails and re-renders index" do
    # users(:one) is already on voyage via fixture
    sign_in_as users(:one)
    assert_no_difference "SailingParticipant.count" do
      post sailing_sailing_participants_path(sailings(:voyage)),
           params: { sailing_participant: { status: "EOI" } }
    end
    assert_response :unprocessable_entity
  end

  # --- bulk_update ---

  test "member cannot bulk update" do
    sign_in_as users(:member)
    patch bulk_update_sailing_sailing_participants_path(sailings(:voyage)),
          params: { statuses: {} }
    assert_redirected_to root_path
  end

  test "office_staff can bulk update participant statuses" do
    sp = sailing_participants(:one_on_voyage)
    sign_in_as users(:office_staff)
    patch bulk_update_sailing_sailing_participants_path(sailings(:voyage)),
          params: { statuses: { sp.id.to_s => "Accepted" }, attended: { sp.id.to_s => "0" } }
    assert_redirected_to sailing_sailing_participants_path(sailings(:voyage))
    assert_equal "Accepted", sp.reload.status
  end

  # --- edit / update ---

  test "user can edit their own registration comment" do
    sp = sailing_participants(:one_on_voyage)
    sign_in_as users(:one)
    patch sailing_participant_path(sp),
          params: { sailing_participant: { status: sp.status, comment: "my comment" } }
    assert_redirected_to sailings_path
    assert_equal "my comment", sp.reload.comment
  end

  # --- destroy ---

  test "user can cancel their own registration" do
    sp = sailing_participants(:one_on_voyage)
    sign_in_as users(:one)
    assert_difference "SailingParticipant.count", -1 do
      delete sailing_participant_path(sp)
    end
    assert_redirected_to sailings_path
  end

  test "user cannot cancel another user's registration" do
    sp = sailing_participants(:two_on_voyage)
    sign_in_as users(:one)
    delete sailing_participant_path(sp)
    assert sp.reload.persisted?, "Other user's registration should not be destroyed"
  end
end
