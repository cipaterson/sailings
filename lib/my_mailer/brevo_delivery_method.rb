require "net/http"

module MyMailer
  class BrevoDeliveryMethod
    API_URL = "https://api.brevo.com/v3/smtp/email"

    def initialize(config)
      @api_key = config[:api_key]
    end

    def deliver!(mail)
      uri = URI(API_URL)
      req = Net::HTTP::Post.new(uri)
      req["Content-Type"] = "application/json"
      req["api-key"] = @api_key

      from_header  = mail[:from]
      sender_email = from_header.addresses.first
      sender_name  = from_header.display_names.first.presence || sender_email

      req.body = {
        sender:      { name: sender_name, email: sender_email },
        to:          mail.to.map { |addr| { email: addr } },
        subject:     mail.subject,
        htmlContent: html_body(mail),
        textContent: text_body(mail)
      }.compact.to_json

      response = execute_http(uri, req)

      unless response.code == "201"
        Rails.logger.error("Brevo delivery failed (#{response.code}): #{response.body}")
        raise "Brevo API error #{response.code}: #{response.body}"
      end
    end

    private

    def execute_http(uri, req)
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10) do |http|
        http.request(req)
      end
    end

    def html_body(mail)
      if mail.multipart?
        mail.html_part&.decoded
      elsif mail.content_type&.start_with?("text/html")
        mail.decoded
      end
    end

    def text_body(mail)
      if mail.multipart?
        mail.text_part&.decoded
      elsif mail.content_type&.start_with?("text/plain")
        mail.decoded
      end
    end
  end
end
