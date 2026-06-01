module ApplicationHelper
  def can?(role)
    current_user&.has_role?(role.to_s)
  end

  def charter_calendar_class(sailing)
    return nil unless sailing.charterer.present?
    { "TBC" => "charter-tbc", "Confirmed" => "charter-confirmed",
      "Outstanding" => "charter-outstanding", "Paid" => "charter-paid" }[sailing.charter_state]
  end
end
