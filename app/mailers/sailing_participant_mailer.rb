class SailingParticipantMailer < ApplicationMailer
  def status_changed(sailing_participant, old_status)
    @sailing_participant = sailing_participant
    @sailing = sailing_participant.sailing
    @user = sailing_participant.user
    @old_status = old_status
    @new_status = sailing_participant.status

    mail(
      to: @user.email_address,
      subject: "Your registration status has been updated"
    )
  end
end
