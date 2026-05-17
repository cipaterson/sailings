require "application_system_test_case"

class MyRegistrationsTest < ApplicationSystemTestCase
  test "member with no registrations sees empty message" do
    sign_in_as users(:member)
    click_on "My Registrations"
    assert_selector "p", text: /no registrations/i
  end

  test "member sees their registrations" do
    sign_in_as users(:one)
    click_on "My Registrations"
    assert_selector "h1", text: "My Registrations"
    assert_selector "td", text: /EOI|Accepted|Not-required/
  end

  test "member can cancel a registration" do
    sign_in_as users(:one)
    click_on "My Registrations"

    assert_difference -> { SailingParticipant.count }, -1 do
      accept_confirm { click_on "Cancel" }
      # Wait for redirect back to page
      assert_selector "h1", text: "My Registrations"
    end
  end
end
