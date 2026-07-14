# A member's registration for a voyage (a SailingParticipant row), with the
# voyage nested so the app can render a registrations list without a second call.
class RegistrationSerializer
  # SailingParticipant#climbing is stored as 1 = Yes, 2 = No, matching the web form.
  CLIMBING = { 1 => "Yes", 2 => "No" }.freeze

  def initialize(participant)
    @participant = participant
  end

  def as_json(*)
    {
      id: @participant.id,
      status: @participant.status,
      comment: @participant.comment,
      climbing: CLIMBING[@participant.climbing],
      attended: @participant.attended.to_i == 1,
      created_at: @participant.created_at&.iso8601,
      sailing: SailingSerializer.new(@participant.sailing).as_json
    }
  end
end
