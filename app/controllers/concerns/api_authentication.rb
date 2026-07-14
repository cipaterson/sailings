module ApiAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def current_user
      Current.user
    end

    def require_authentication
      resume_session || render_unauthorized
    end

    def resume_session
      Current.session ||= Session.find_by_token(bearer_token)
    end

    def bearer_token
      request.authorization.to_s[/\ABearer (.+)\z/, 1]
    end

    def render_unauthorized
      render json: { error: "Unauthorized" }, status: :unauthorized
    end

    # Mirrors ApplicationController#require_role!, but answers with 403 JSON
    # rather than redirecting to the root path.
    def require_role!(*roles)
      unless roles.any? { |r| Current.user&.has_role?(r.to_s) }
        render json: { error: "Forbidden" }, status: :forbidden
      end
    end
end
