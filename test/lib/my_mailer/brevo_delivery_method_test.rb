require "test_helper"
require "my_mailer/brevo_delivery_method"

class MyMailer::BrevoDeliveryMethodTest < ActiveSupport::TestCase
  FakeResponse = Data.define(:code, :body)

  # Test subclass that captures the HTTP request instead of making a real call.
  class FakeBrevoDelivery < MyMailer::BrevoDeliveryMethod
    attr_reader :last_request

    def initialize(settings, fake_response)
      super(settings)
      @fake_response = fake_response
    end

    private

    def execute_http(_uri, req)
      @last_request = req
      @fake_response
    end
  end

  setup do
    @ok_response  = FakeResponse.new(code: "201", body: '{"messageId":"<abc@brevo.com>"}')
    @err_response = FakeResponse.new(code: "400", body: '{"message":"Invalid API key"}')
  end

  test "delivers multipart mail and builds correct Brevo payload" do
    mail = Mail.new do
      from    "Sender Name <sender@example.com>"
      to      "recipient@example.com"
      subject "Test Subject"
    end
    mail.html_part = Mail::Part.new { content_type "text/html; charset=UTF-8"; body "<p>Hello</p>" }
    mail.text_part = Mail::Part.new { content_type "text/plain; charset=UTF-8"; body "Hello" }

    delivery = FakeBrevoDelivery.new({ api_key: "test-key-123" }, @ok_response)
    delivery.deliver!(mail)

    payload = JSON.parse(delivery.last_request.body)
    assert_equal "test-key-123",          delivery.last_request["api-key"]
    assert_equal "application/json",      delivery.last_request["Content-Type"]
    assert_equal "Test Subject",          payload["subject"]
    assert_equal "sender@example.com",    payload.dig("sender", "email")
    assert_equal "Sender Name",           payload.dig("sender", "name")
    assert_equal "recipient@example.com", payload.dig("to", 0, "email")
    assert_equal "<p>Hello</p>",          payload["htmlContent"]
    assert_equal "Hello",                 payload["textContent"]
  end

  test "falls back to email as sender name when no display name" do
    mail = Mail.new { from "plain@example.com"; to "r@example.com"; subject "X"; body "Y" }
    mail.content_type = "text/plain"

    delivery = FakeBrevoDelivery.new({ api_key: "k" }, @ok_response)
    delivery.deliver!(mail)

    payload = JSON.parse(delivery.last_request.body)
    assert_equal "plain@example.com", payload.dig("sender", "name")
    assert_equal "plain@example.com", payload.dig("sender", "email")
  end

  test "raises on non-201 response" do
    mail = Mail.new { from "a@b.com"; to "c@d.com"; subject "X"; body "Y" }
    mail.content_type = "text/plain"

    delivery = FakeBrevoDelivery.new({ api_key: "k" }, @err_response)
    assert_raises(RuntimeError) { delivery.deliver!(mail) }
  end
end
