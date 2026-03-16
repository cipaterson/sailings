class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

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
