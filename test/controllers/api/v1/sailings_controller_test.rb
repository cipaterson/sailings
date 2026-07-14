require "test_helper"

class Api::V1::SailingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @member  = users(:member)
    @headers = api_headers_for(@member)
    # Created with relative dates so "upcoming" stays true as the fixtures age.
    @upcoming = Sailing.create!(purpose: "Twilight sail", sailing_type: "Sail", status: "scheduled",
                                departs_at: 3.days.from_now, returns_at: 3.days.from_now + 4.hours,
                                master: "A. Master", confirm_overlap: true)
  end

  test "requests without a token are rejected with 401 JSON, not a redirect" do
    get api_v1_sailings_url

    assert_response :unauthorized
    assert_equal "Unauthorized", json_response["error"]
  end

  test "a bogus token is rejected" do
    get api_v1_sailings_url, headers: { "Authorization" => "Bearer not-a-real-token" }

    assert_response :unauthorized
  end

  test "index lists upcoming scheduled voyages" do
    get api_v1_sailings_url, headers: @headers

    assert_response :success
    ids = json_response.map { |s| s["id"] }
    assert_includes ids, @upcoming.id
  end

  test "index excludes voyages that have already departed" do
    past = Sailing.create!(purpose: "Last month", sailing_type: "Sail", status: "scheduled",
                           departs_at: 30.days.ago, returns_at: 30.days.ago + 4.hours,
                           confirm_overlap: true)

    get api_v1_sailings_url, headers: @headers

    assert_not_includes json_response.map { |s| s["id"] }, past.id
  end

  test "index excludes drafts" do
    draft = Sailing.create!(purpose: "Not yet scheduled", sailing_type: "Sail", status: "draft")

    get api_v1_sailings_url, headers: @headers

    assert_not_includes json_response.map { |s| s["id"] }, draft.id
  end

  test "the payload never exposes charter or financial fields" do
    @upcoming.update!(charterer: "Acme Corp", charter_state: "Paid", quoted_cost_cents: 500_00,
                      confirm_overlap: true)

    get api_v1_sailing_url(@upcoming), headers: @headers

    assert_response :success
    %w[charterer charter_state quoted_cost_cents quoted_cost deposit_cents final_amount_cents
       receipt_no invoice_date].each do |field|
      assert_not json_response.key?(field), "#{field} must not be exposed to the app"
    end
  end

  test "show reports the member's own registration when they have one" do
    registration = SailingParticipant.create!(sailing: @upcoming, user: @member, status: "EOI")

    get api_v1_sailing_url(@upcoming), headers: @headers

    assert_equal registration.id, json_response["my_registration"]["id"]
    assert_equal "EOI", json_response["my_registration"]["status"]
  end

  test "show reports no registration when the member has not registered" do
    get api_v1_sailing_url(@upcoming), headers: @headers

    assert_nil json_response["my_registration"]
  end

  test "another member's registration is not reported as mine" do
    SailingParticipant.create!(sailing: @upcoming, user: users(:one), status: "Accepted")

    get api_v1_sailing_url(@upcoming), headers: @headers

    assert_nil json_response["my_registration"]
    assert_equal 1, json_response["participants_count"]
  end

  test "an unknown voyage returns 404 JSON" do
    get api_v1_sailing_url(id: 999_999), headers: @headers

    assert_response :not_found
    assert_equal "Not found", json_response["error"]
  end
end
