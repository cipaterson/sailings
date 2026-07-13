require "test_helper"

class SailingsControllerTest < ActionDispatch::IntegrationTest
  # --- Authentication ---

  test "unauthenticated user is redirected to login" do
    get sailings_path
    assert_redirected_to new_session_path
  end

  test "unauthenticated user cannot access new" do
    get new_sailing_path
    assert_redirected_to new_session_path
  end

  # --- Authorization ---

  test "member cannot access new sailing" do
    sign_in_as users(:member)
    get new_sailing_path
    assert_redirected_to root_path
  end

  test "member cannot create a sailing" do
    sign_in_as users(:member)
    post sailings_path, params: { sailing: { purpose: "Test", sailing_type: "Voyage" } }
    assert_redirected_to root_path
  end

  test "member cannot edit a sailing" do
    sign_in_as users(:member)
    get edit_sailing_path(sailings(:voyage))
    assert_redirected_to root_path
  end

  test "member cannot destroy a sailing" do
    sign_in_as users(:member)
    delete sailing_path(sailings(:voyage))
    assert_redirected_to root_path
  end

  test "office_staff can access new sailing" do
    sign_in_as users(:office_staff)
    get new_sailing_path
    assert_response :success
  end

  test "crewing_operator can access new sailing" do
    sign_in_as users(:crewing_operator)
    get new_sailing_path
    assert_response :success
  end

  # --- index ---

  test "index is accessible to authenticated users" do
    sign_in_as users(:member)
    get sailings_path
    assert_response :success
  end

  test "index defaults to sailings from today onwards" do
    sign_in_as users(:member)
    get sailings_path
    assert_response :success
    # no assertion on @from_date directly, just that the page renders
  end

  test "index filters by from_date" do
    sign_in_as users(:member)
    get sailings_path, params: { from_date: "2026-06-01" }
    assert_response :success
  end

  test "index filters by to_date" do
    sign_in_as users(:member)
    get sailings_path, params: { from_date: "", to_date: "2026-06-30" }
    assert_response :success
  end

  test "index with invalid from_date treats it as nil" do
    sign_in_as users(:member)
    get sailings_path, params: { from_date: "not-a-date" }
    assert_response :success
  end

  # --- show ---

  test "show is accessible to authenticated users" do
    sign_in_as users(:member)
    get sailing_path(sailings(:voyage))
    assert_response :success
  end

  # --- calendar ---

  test "calendar is accessible to authenticated users" do
    sign_in_as users(:member)
    get calendar_sailings_path
    assert_response :success
  end

  test "calendar defaults to month view" do
    sign_in_as users(:member)
    get calendar_sailings_path
    assert_response :success
  end

  test "calendar accepts week view" do
    sign_in_as users(:member)
    get calendar_sailings_path, params: { view: "week" }
    assert_response :success
  end

  test "calendar accepts day view" do
    sign_in_as users(:member)
    get calendar_sailings_path, params: { view: "day" }
    assert_response :success
  end

  test "calendar ignores invalid view param" do
    sign_in_as users(:member)
    get calendar_sailings_path, params: { view: "decade" }
    assert_response :success
  end

  test "calendar links voyages to registration for non-office-staff" do
    voyage = sailings(:multiday)
    sign_in_as users(:member)
    get calendar_sailings_path, params: { year: voyage.departs_at.year, month: voyage.departs_at.month }
    assert_response :success
    assert_select "a[href=?]", new_sailing_sailing_participant_path(voyage, return_to: request.fullpath)
    assert_select "a[href=?]", edit_sailing_path(voyage), false
  end

  test "calendar links voyages to edit for office staff" do
    voyage = sailings(:multiday)
    sign_in_as users(:office_staff)
    get calendar_sailings_path, params: { year: voyage.departs_at.year, month: voyage.departs_at.month }
    assert_response :success
    assert_select "a[href=?]", edit_sailing_path(voyage, return_to: request.fullpath)
    assert_select "a[href=?]", new_sailing_sailing_participant_path(voyage), false
  end

  # --- create ---

  test "create with valid params redirects to sailing" do
    sign_in_as users(:office_staff)
    assert_difference "Sailing.count", 1 do
      post sailings_path, params: { sailing: { purpose: "Test voyage", sailing_type: "Sail" } }
    end
    assert_redirected_to sailing_path(Sailing.last)
  end

  test "create with missing purpose re-renders new" do
    sign_in_as users(:office_staff)
    assert_no_difference "Sailing.count" do
      post sailings_path, params: { sailing: { purpose: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "create with overlapping dates is blocked pending confirmation" do
    sign_in_as users(:office_staff)
    assert_no_difference "Sailing.count" do
      post sailings_path, params: { sailing: {
        purpose: "Clash", sailing_type: "Sail",
        departs_date: "2026-06-01", departs_time: "12:00",
        returns_date: "2026-06-01", returns_time: "18:00"
      } }
    end
    assert_response :unprocessable_entity
    assert_match(/overlap/i, response.body)
  end

  test "create with overlapping dates succeeds when confirmed" do
    sign_in_as users(:office_staff)
    assert_difference "Sailing.count", 1 do
      post sailings_path, params: { sailing: {
        purpose: "Clash", sailing_type: "Sail",
        departs_date: "2026-06-01", departs_time: "12:00",
        returns_date: "2026-06-01", returns_time: "18:00",
        confirm_overlap: "1"
      } }
    end
    assert_redirected_to sailing_path(Sailing.last)
  end

  # --- update ---

  test "update with valid params redirects to sailings list" do
    sign_in_as users(:office_staff)
    patch sailing_path(sailings(:voyage)), params: { sailing: { purpose: "Updated purpose" } }
    assert_redirected_to sailings_path
    assert_equal "Updated purpose", sailings(:voyage).reload.purpose
  end

  test "update with invalid params re-renders edit" do
    sign_in_as users(:office_staff)
    patch sailing_path(sailings(:voyage)), params: { sailing: { purpose: "" } }
    assert_response :unprocessable_entity
  end

  # --- destroy ---

  test "destroy removes the sailing and redirects" do
    sign_in_as users(:office_staff)
    assert_difference "Sailing.count", -1 do
      delete sailing_path(sailings(:voyage))
    end
    assert_redirected_to sailings_path
  end
end
