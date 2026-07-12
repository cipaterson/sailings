require "application_system_test_case"

class SailingsTest < ApplicationSystemTestCase
  # --- Voyages list ---

  test "member sees the voyages list after signing in" do
    sign_in_as users(:member)
    assert_selector "h1", text: "Voyages"
  end

  test "member does not see New Voyage button" do
    sign_in_as users(:member)
    assert_no_selector "a", text: "New Voyage"
  end

  test "office_staff sees New Voyage button" do
    sign_in_as users(:office_staff)
    assert_selector "a", text: "New Voyage"
  end

  test "member can register for a sailing from the list" do
    sign_in_as users(:member)
    visit sailings_path(from_date: "")

    within("tbody tr", match: :first) do
      click_on "Register"
    end

    # Register now opens a form; submit it to complete registration
    click_on "Submit"

    assert_current_path sailings_path
    assert_text /registered/i
  end

  test "already-registered sailing shows Registered instead of Register button" do
    sign_in_as users(:one)
    visit sailings_path(from_date: "")

    # users(:one) is registered for :voyage via fixture
    assert_selector "td a", text: "Registered"
  end

  # --- Creating a sailing ---

  test "office_staff can create a new sailing" do
    sign_in_as users(:office_staff)
    click_on "New Voyage"

    fill_in "Voyage Purpose", with: "System test voyage"
    select "Sail", from: "Sailing Type"
    click_on "Create Voyage"

    assert_selector "h1", text: "System test voyage"
    assert_selector "td", text: "System test voyage"
  end

  test "creating a sailing without a purpose shows errors" do
    sign_in_as users(:office_staff)
    visit new_sailing_path
    find('input[type="submit"]').click

    assert_selector "li", text: /purpose/i
  end

  test "selecting a departure date fills a blank return date" do
    sign_in_as users(:office_staff)
    visit new_sailing_path

    # Set the date value directly and fire change — typing into a native date
    # input via Selenium is locale-dependent and unreliable.
    departs = find_field("Departure Date")
    page.execute_script(
      "arguments[0].value = '2026-06-01'; arguments[0].dispatchEvent(new Event('change'))",
      departs
    )

    assert_equal "2026-06-01", find_field("Return Date").value
  end

  # --- Editing a sailing ---

  test "office_staff can edit a sailing" do
    sign_in_as users(:office_staff)
    visit edit_sailing_path(sailings(:voyage))

    fill_in "Voyage Purpose", with: "Updated harbour cruise"
    click_on "Update Voyage"

    assert_current_path sailings_path
    assert_equal "Updated harbour cruise", sailings(:voyage).reload.purpose
  end

  # --- Deleting a sailing ---

  # --- Calendar ---

  test "member can view the calendar" do
    sign_in_as users(:member)
    click_on "Calendar"
    assert_selector "h1", text: /Voyages/i
  end

  test "calendar shows week view when requested" do
    sign_in_as users(:member)
    visit calendar_sailings_path(view: "week")
    assert_selector "h1", text: /Week of/i
  end
end
