require "net/http"

module ActionMailer
  class BrevoDeliveryMethod
    attr_accessor :settings

    API_URL = "https://api.brevo.com/v3/smtp/email"

    def initialize(settings)
      @api_key = settings[:api_key]
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
      Rails.logger.error("Brevo delivery (#{response.code}): #{response.body}")

      unless response.code == "201"
        Rails.logger.error("Brevo delivery failed (#{response.code}): #{response.body}")
        raise "Brevo API error #{response.code}: #{response.body}"
      end
    end

    private

    def execute_http(uri, req)
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
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
