class SettingsController < ApplicationController
  before_action :require_office_staff!

  def edit
    load_settings
  end

  def update
    @office_email   = params[:office_email].to_s.strip
    @charter_colors = AppConfig::DEFAULT_CHARTER_COLORS.keys.index_with do |name|
      params.dig(:charter_colors, name).to_s.strip
    end

    if valid_settings?
      Setting.write("office_email", @office_email)
      Setting.write("charter_colors", @charter_colors)
      redirect_to edit_settings_path, notice: "Settings saved."
    else
      flash.now[:alert] = @errors.join(" ")
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def load_settings
    @office_email   = AppConfig.office_email
    @charter_colors = AppConfig.charter_colors
  end

  def valid_settings?
    @errors = []
    unless @office_email.match?(URI::MailTo::EMAIL_REGEXP)
      @errors << "Office email is not a valid email address."
    end
    invalid = @charter_colors.reject { |_name, color| color.match?(AppConfig::CSS_COLOR) }
    if invalid.any?
      @errors << "Invalid color for: #{invalid.keys.join(', ')}."
    end
    @errors.empty?
  end
end
