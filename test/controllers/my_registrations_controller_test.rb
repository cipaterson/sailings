require "test_helper"

class MyRegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get my_registrations_show_url
    assert_response :success
  end
end
