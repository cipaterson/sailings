module Api
  module V1
    class SessionsController < BaseController
      allow_unauthenticated_access only: :create

      rate_limit to: 10, within: 3.minutes, only: :create,
                 with: -> { render json: { error: "Try again later." }, status: :too_many_requests }

      def create
        user = User.authenticate_by(params.permit(:email_address, :password))

        return render json: { error: "Try another email address or password." }, status: :unauthorized if user.nil?

        # The same two guards the web SessionsController applies after a correct password.
        if !user.approved?
          return render json: { error: "Your membership application is still pending approval." },
                        status: :forbidden
        elsif user.roles.empty?
          return render json: { error: "Your account has been disabled. Please contact the club office." },
                        status: :forbidden
        end

        session = Session.start_with_token!(user, user_agent: request.user_agent, ip_address: request.remote_ip)
        render json: { token: session.token, user: ProfileSerializer.new(user).as_json }, status: :created
      end

      def destroy
        Current.session.destroy
        head :no_content
      end
    end
  end
end
