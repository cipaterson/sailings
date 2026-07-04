module ApplicationHelper
  def can?(role)
    current_user&.has_role?(role.to_s)
  end

  def charter_calendar_class(sailing)
    return nil unless sailing.charterer.present?
    { "TBC" => "charter-tbc", "Confirmed" => "charter-confirmed",
      "Outstanding" => "charter-outstanding", "Paid" => "charter-paid" }[sailing.charter_state]
  end

  # Accepts hex, rgb[a]/hsl[a], or named colors; anything else is dropped so a
  # future admin-config value can't inject arbitrary CSS.
  CSS_COLOR = %r{\A#[0-9a-fA-F]{3,8}\z|\A(?:rgb|rgba|hsl|hsla)\([0-9%.,\s/]+\)\z|\A[a-zA-Z]+\z}

  # Emits a :root block of --charter-* CSS variables from AppConfig, consumed by
  # the .charter-* rules in calender.css.
  def charter_color_style_tag(colors = AppConfig.charter_colors)
    decls = colors.filter_map do |name, color|
      "--charter-#{name}: #{color};" if color.to_s.match?(CSS_COLOR)
    end
    tag.style(":root { #{decls.join(' ')} }".html_safe) if decls.any?
  end
end
