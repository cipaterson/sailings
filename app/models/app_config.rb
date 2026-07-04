# Central application configuration façade.
#
# Reads values from the DB-backed Setting store, falling back to the in-code
# defaults below when a value is unset (or before the settings table exists).
# App code should read through here (e.g. AppConfig.office_email) — office staff
# edit the stored values via the Settings screen.
class AppConfig
  # Accepts hex, rgb[a]/hsl[a], or named colors; anything else is rejected so a
  # stored (admin-entered) value can't inject arbitrary CSS.
  CSS_COLOR = %r{\A#[0-9a-fA-F]{3,8}\z|\A(?:rgb|rgba|hsl|hsla)\([0-9%.,\s/]+\)\z|\A[a-zA-Z]+\z}

  # Fallback recipient for office notifications (also overridable via OFFICE_EMAIL).
  DEFAULT_OFFICE_EMAIL = "office@zzyplza.com".freeze

  # Fallback charter voyage calendar colors, keyed by charter-state suffix
  # (see ApplicationHelper#charter_calendar_class).
  DEFAULT_CHARTER_COLORS = {
    "tbc"         => "#e0e0e0",
    "confirmed"   => "#fff176",
    "outstanding" => "#ef9a9a",
    "paid"        => "#a5d6a7"
  }.freeze

  # Recipient for membership applications and other office notifications.
  def self.office_email
    ENV["OFFICE_EMAIL"].presence || Setting["office_email"].presence || DEFAULT_OFFICE_EMAIL
  end

  # Charter colors, stored overrides merged over the defaults so every state
  # always resolves to a color even if only some are customized.
  def self.charter_colors
    DEFAULT_CHARTER_COLORS.merge(Setting["charter_colors"] || {})
  end
end
