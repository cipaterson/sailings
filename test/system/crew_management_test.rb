require "application_system_test_case"

class CrewManagementTest < ApplicationSystemTestCase
  test "crewing_operator sees Manage Crew button on sailings list" do
    sign_in_as users(:crewing_operator)
    visit sailings_path(from_date: "")
    assert_selector "a", text: "Manage Crew"
  end

  test "member does not see Manage Crew button" do
    sign_in_as users(:member)
    visit sailings_path(from_date: "")
    assert_no_selector "a", text: "Manage Crew"
  end

  test "crewing_operator can view crew list for a sailing" do
    sign_in_as users(:crewing_operator)
    visit sailing_sailing_participants_path(sailings(:voyage))

    assert_selector "h1", text: /Harbour cruise/i
    assert_selector "td", text: users(:one).email_address
    assert_selector "td", text: users(:two).email_address
  end

  test "crewing_operator can add a crew member" do
    sign_in_as users(:crewing_operator)
    visit sailing_sailing_participants_path(sailings(:multiday))

    # The "Member" select is enhanced by TomSelect (searchable-select controller),
    # which hides the native <select>, so drive the rendered widget directly.
    find(".ts-control").click
    find(".ts-dropdown .option", text: users(:member).email_address).click
    click_on "Add Crew Member"

    assert_current_path sailing_sailing_participants_path(sailings(:multiday))
    assert_selector "[style*='color:green']", text: /successfully added/i
  end

  test "crewing_operator can bulk update participant statuses" do
    sp = sailing_participants(:one_on_voyage)
    sign_in_as users(:crewing_operator)
    visit sailing_sailing_participants_path(sailings(:voyage))

    select "Accepted", from: "statuses[#{sp.id}]"
    click_on "Save All"

    assert_current_path sailing_sailing_participants_path(sailings(:voyage))
    assert_equal "Accepted", sp.reload.status
  end

  test "crewing_operator can mark a participant as attended" do
    sp = sailing_participants(:one_on_voyage)
    sign_in_as users(:crewing_operator)
    visit sailing_sailing_participants_path(sailings(:voyage))

    check "attended[#{sp.id}]"
    click_on "Save All"

    # Verify persisted by reloading the page and checking the checkbox is still checked
    visit sailing_sailing_participants_path(sailings(:voyage))
    assert find("input[name='attended[#{sp.id}]']").checked?
  end
end
