class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

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

    def require_office_staff_or_crewing_operator!
      require_role!("office_staff", "crewing_operator")
    end
end
