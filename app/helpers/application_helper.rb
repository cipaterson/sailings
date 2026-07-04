module ApplicationHelper
  def can?(role)
    current_user&.has_role?(role.to_s)
  end

  def charter_calendar_class(sailing)
    return nil unless sailing.charterer.present?
    { "TBC" => "charter-tbc", "Confirmed" => "charter-confirmed",
      "Outstanding" => "charter-outstanding", "Paid" => "charter-paid" }[sailing.charter_state]
  end

  # Emits a :root block of --charter-* CSS variables from AppConfig, consumed by
  # the .charter-* rules in calender.css. Invalid colors are dropped (see
  # AppConfig::CSS_COLOR) so a stored value can't inject arbitrary CSS.
  def charter_color_style_tag(colors = AppConfig.charter_colors)
    decls = colors.filter_map do |name, color|
      "--charter-#{name}: #{color};" if color.to_s.match?(AppConfig::CSS_COLOR)
    end
    tag.style(":root { #{decls.join(' ')} }".html_safe) if decls.any?
  end
end
