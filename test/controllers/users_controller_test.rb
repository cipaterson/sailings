require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @office_staff = users(:one)  # has roles_mask: 2 (office_staff)
    sign_in_as(@office_staff)
  end

  test "index defaults to sorting by last name ascending" do
    get users_path
    assert_response :success

    names = css_select("tbody tr td:first-child a").map(&:text)
    assert_equal [ "Bob Apple", "Alice Zebra" ], names
  end

  test "index sorts by last name descending" do
    get users_path, params: { sort: "last_name", direction: "desc" }
    assert_response :success

    names = css_select("tbody tr td:first-child a").map(&:text)
    assert_equal [ "Alice Zebra", "Bob Apple" ], names
  end

  test "index sorts by membership type ascending" do
    get users_path, params: { sort: "membership_type", direction: "asc" }
    assert_response :success

    types = css_select("tbody tr td:nth-child(4)").map(&:text)
    assert_equal [ "Individual", "Life" ], types
  end

  test "index ignores unknown sort columns" do
    get users_path, params: { sort: "password_digest", direction: "asc" }
    assert_response :success

    # Falls back to default last_name asc — just check it doesn't blow up
    names = css_select("tbody tr td:first-child a").map(&:text)
    assert_equal [ "Bob Apple", "Alice Zebra" ], names
  end

  test "index shows sort indicators in column headers" do
    get users_path, params: { sort: "last_name", direction: "asc" }
    assert_response :success
    assert_select "thead th a", text: /Name.*▲/
  end
end
