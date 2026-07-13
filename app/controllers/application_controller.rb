class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :home_path_for

  # Maps a user's chosen home page (User::HOME_PAGES key) to a path. Used for the
  # Home nav link and the post-login redirect. Falls back to root for blank or
  # "voyages".
  def home_path_for(user)
    case user&.preferred_home
    when "calendar"          then calendar_sailings_path
    when "my_registrations"  then my_registrations_path
    when "maintenance_tasks" then in_progress_maintenance_tasks_path
    else root_path
    end
  end

  private

    # Returns params[:return_to] when it is a safe internal path (single leading
    # slash, not protocol-relative), otherwise the given default. Prevents
    # open-redirects while letting edit forms send the user back to their origin.
    def safe_return_to(default)
      to = params[:return_to].to_s
      to.start_with?("/") && !to.start_with?("//") ? to : default
    end

    def require_role!(*roles)
      unless roles.any? { |r| Current.user&.has_role?(r.to_s) }
        redirect_to root_path, alert: "You are not authorized to perform this action."
      end
    end

    def require_office_staff!
      require_role!("office_staff")
    end

    # Intentionally retained for future use (no current callers).
    def require_crewing_operator!
      require_role!("crewing_operator")
    end

    def require_office_staff_or_crewing_operator!
      require_role!("office_staff", "crewing_operator")
    end
end
