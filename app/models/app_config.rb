# Central application configuration façade.
#
# For now these are in-code defaults with optional ENV overrides. A future
# admin settings UI can back these methods with a DB-driven store without
# changing any call sites (e.g. AppConfig.office_email). This is also the
# natural home for other configurable values (colors, etc.) added later.
class AppConfig
  # Edit this to change where office notifications go, or set OFFICE_EMAIL.
  DEFAULT_OFFICE_EMAIL = "office@zzyplza.com".freeze

  # Recipient for membership applications and other office notifications.
  def self.office_email
    ENV.fetch("OFFICE_EMAIL", DEFAULT_OFFICE_EMAIL)
  end
end
