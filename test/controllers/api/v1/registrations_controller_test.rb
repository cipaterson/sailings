require "test_helper"

class Api::V1::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @member  = users(:member)
    @headers = api_headers_for(@member)
    @sailing = Sailing.create!(purpose: "Twilight sail", sailing_type: "Sail", status: "scheduled",
                               departs_at: 3.days.from_now, returns_at: 3.days.from_now + 4.hours,
                               confirm_overlap: true)
  end

  test "index returns only my own registrations" do
    mine = SailingParticipant.create!(sailing: @sailing, user: @member, status: "EOI")
    SailingParticipant.create!(sailing: @sailing, user: users(:one), status: "Accepted")

    get api_v1_registrations_url, headers: @headers

    assert_response :success
    assert_equal [ mine.id ], json_response.map { |r| r["id"] }
    assert_equal @sailing.id, json_response.first["sailing"]["id"]
  end

  test "registering creates an EOI for the signed-in member" do
    assert_difference -> { @member.sailing_participants.count }, 1 do
      post api_v1_sailing_registrations_url(@sailing), headers: @headers,
           params: { comment: "Happy to cook", climbing: 1 }
    end

    assert_response :created
    assert_equal "EOI", json_response["status"]
    assert_equal "Happy to cook", json_response["comment"]
    assert_equal "Yes", json_response["climbing"]
    assert_equal @member.id, SailingParticipant.find(json_response["id"]).user_id
  end

  test "registering works without a body" do
    post api_v1_sailing_registrations_url(@sailing), headers: @headers

    assert_response :created
    assert_equal "EOI", json_response["status"]
  end

  test "registering twice for the same voyage is rejected" do
    SailingParticipant.create!(sailing: @sailing, user: @member, status: "EOI")

    assert_no_difference -> { SailingParticipant.count } do
      post api_v1_sailing_registrations_url(@sailing), headers: @headers
    end

    assert_response :unprocessable_entity
    assert json_response["errors"].present?
  end

  test "a member cannot register on behalf of somebody else, or grant themselves Accepted" do
    # Neither user_id nor status is permitted, so both are ignored rather than honoured.
    post api_v1_sailing_registrations_url(@sailing), headers: @headers,
         params: { user_id: users(:one).id, status: "Accepted" }

    assert_response :created
    assert_equal @member.id, SailingParticipant.find(json_response["id"]).user_id
    assert_equal "EOI", json_response["status"]
  end

  test "cancelling my own registration removes it" do
    registration = SailingParticipant.create!(sailing: @sailing, user: @member, status: "EOI")

    assert_difference -> { SailingParticipant.count }, -1 do
      delete api_v1_registration_url(registration), headers: @headers
    end

    assert_response :no_content
  end

  test "a member cannot cancel somebody else's registration" do
    theirs = SailingParticipant.create!(sailing: @sailing, user: users(:one), status: "Accepted")

    assert_no_difference -> { SailingParticipant.count } do
      delete api_v1_registration_url(theirs), headers: @headers
    end

    assert_response :not_found
  end

  test "registrations require authentication" do
    get api_v1_registrations_url

    assert_response :unauthorized
  end
end
