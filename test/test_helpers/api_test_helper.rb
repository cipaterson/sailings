module ApiTestHelper
  # Issues a real API session and returns headers ready to pass to an
  # integration request: `get api_v1_sailings_url, headers: api_headers_for(user)`
  def api_headers_for(user)
    token = Session.start_with_token!(user).token
    { "Authorization" => "Bearer #{token}" }
  end

  def json_response
    JSON.parse(response.body)
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include ApiTestHelper
end
