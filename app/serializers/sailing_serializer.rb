# Member-facing view of a Sailing (a "Voyage" in the UI).
#
# The charter and financial attributes — charterer, charter_state,
# quoted_cost_cents, deposit_cents, final_amount_cents and the invoice/receipt
# fields — are office-staff-only in the web app and are deliberately absent here.
class SailingSerializer
  def initialize(sailing, participants_count: nil)
    @sailing = sailing
    @participants_count = participants_count
  end

  def as_json(*)
    {
      id: @sailing.id,
      purpose: @sailing.purpose,
      display_name: @sailing.display_name,
      sailing_type: @sailing.sailing_type,
      status: @sailing.status,
      training: @sailing.training,
      departs_at: @sailing.departs_at&.iso8601,
      returns_at: @sailing.returns_at&.iso8601,
      voyage_dates: @sailing.voyage_dates,
      master: @sailing.master,
      engineer: @sailing.engineer,
      ln_contact: @sailing.ln_contact,
      comments: @sailing.comments,
      additional_details: @sailing.additional_details,
      participants_count: participants_count
    }
  end

  private

  def participants_count
    @participants_count ||
      (@sailing.participants_count if @sailing.respond_to?(:participants_count)) ||
      @sailing.sailing_participants.size
  end
end
