require "test_helper"

class Api::V1::SessionsControllerTest < ActionDispatch::IntegrationTest
  test "logging in returns a bearer token and the user" do
    post api_v1_session_url, params: { email_address: users(:member).email_address, password: "password" }

    assert_response :created
    assert json_response["token"].present?
    assert_equal users(:member).email_address, json_response["user"]["email_address"]
  end

  test "the issued token authenticates subsequent requests" do
    post api_v1_session_url, params: { email_address: users(:member).email_address, password: "password" }
    token = json_response["token"]

    get api_v1_profile_url, headers: { "Authorization" => "Bearer #{token}" }

    assert_response :success
    assert_equal users(:member).email_address, json_response["email_address"]
  end

  test "the raw token is not stored on the session record" do
    post api_v1_session_url, params: { email_address: users(:member).email_address, password: "password" }

    assert_nil Session.find_by(token_digest: json_response["token"]),
               "the raw token must not be stored — only its digest"
    assert Session.find_by_token(json_response["token"]).present?
  end

  test "a wrong password is rejected" do
    post api_v1_session_url, params: { email_address: users(:member).email_address, password: "wrong" }

    assert_response :unauthorized
    assert_nil json_response["token"]
  end

  test "an unapproved member cannot log in" do
    post api_v1_session_url, params: { email_address: users(:pending).email_address, password: "password" }

    assert_response :forbidden
    assert_match(/pending approval/, json_response["error"])
  end

  test "a disabled member cannot log in" do
    users(:member).update!(roles_mask: 0)

    post api_v1_session_url, params: { email_address: users(:member).email_address, password: "password" }

    assert_response :forbidden
    assert_match(/disabled/, json_response["error"])
  end

  test "logging out revokes the token" do
    headers = api_headers_for(users(:member))

    delete api_v1_session_url, headers: headers
    assert_response :no_content

    get api_v1_profile_url, headers: headers
    assert_response :unauthorized
  end
end
