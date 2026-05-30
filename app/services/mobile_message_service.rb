require "net/http"
require "base64"

class MobileMessageService
  API_URL = "https://api.mobilemessage.com.au/v1/messages"

  def initialize
    creds     = Rails.application.credentials.mobile_message!
    @username = creds[:username]
    @password = creds[:password]
    @sender   = creds[:sender]
  end

  # messages: array of { to:, message: } hashes — sent as a single batch request
  def send_batch(messages:)
    uri = URI(API_URL)
    req = Net::HTTP::Post.new(uri)
    req["Content-Type"]  = "application/json"
    req["Authorization"] = "Basic #{Base64.strict_encode64("#{@username}:#{@password}")}"
    req.body = {
      enable_unicode: true,
      messages: messages.map { |m| { to: m[:to], message: m[:message], sender: @sender } }
    }.to_json
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |h|
      # Retrieve the response and log any errors
      response = h.request(req)
      Rails.logger.error response.body if response.code != "200"
    }
  end
end
