module Api
  module V1
    # Inherits from ActionController::API rather than ApplicationController: it
    # carries no CSRF middleware and no cookie/redirect machinery, so there is
    # nothing to skip. A native client is not a browser, so CORS is not needed
    # either.
    class BaseController < ActionController::API
      include ApiAuthentication

      # Off by default the params would be wrapped under a key named for the
      # controller ("session", "registration"), so a flat JSON body would arrive
      # both at the top level and nested. Clients send exactly the documented shape.
      wrap_parameters false

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

      private

      def render_not_found
        render json: { error: "Not found" }, status: :not_found
      end

      def render_invalid(record)
        render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end
end
