require "test_helper"

class Api::V1::ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member)
    @member.update!(first_name: "Ada", last_name: "Lovelace", days_sailed: 12,
                    last_sailed: Date.new(2026, 5, 1),
                    wwvp_qualification: "WWVP-123", wwvp_expires_on: Date.new(2027, 1, 31))
    @headers = api_headers_for(@member)
  end

  test "show returns the signed-in member's own record" do
    get api_v1_profile_url, headers: @headers

    assert_response :success
    assert_equal @member.id, json_response["id"]
    assert_equal "Ada Lovelace", json_response["full_name"]
    assert_equal 12, json_response["sailing_record"]["days_sailed"]
    assert_equal "2026-05-01", json_response["sailing_record"]["last_sailed"]
  end

  test "show returns qualifications with their expiry dates" do
    get api_v1_profile_url, headers: @headers

    wwvp = json_response["qualifications"].find { |q| q["key"] == "wwvp" }
    assert_equal "WWVP", wwvp["label"]
    assert_equal "WWVP-123", wwvp["value"]
    assert_equal "2027-01-31", wwvp["expires_on"]
  end

  test "show never exposes the password digest" do
    get api_v1_profile_url, headers: @headers

    assert_not json_response.key?("password_digest")
  end

  test "profile requires authentication" do
    get api_v1_profile_url

    assert_response :unauthorized
  end
end
