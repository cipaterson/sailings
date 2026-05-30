class SendSmsBatchJob < ApplicationJob
  queue_as :default

  def perform(mobiles:, message:)
    messages = mobiles.map { |m| { to: m, message: message } }
    MobileMessageService.new.send_batch(messages: messages)
  end
end
