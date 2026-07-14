module Api
  module V1
    # The signed-in member's own voyage registrations (SailingParticipant rows).
    #
    # Unlike the web SailingParticipantsController, this only ever acts on
    # Current.user: the staff "register somebody else" path is not exposed, which
    # keeps the endpoint simple and closes that authorization question by
    # construction.
    class RegistrationsController < BaseController
      # Mirrors MyRegistrationsController#show.
      def index
        registrations = Current.user.sailing_participants.includes(:sailing).order(created_at: :desc)
        render json: registrations.map { |r| RegistrationSerializer.new(r).as_json }
      end

      def create
        sailing = Sailing.find(params[:sailing_id])
        registration = sailing.sailing_participants.build(
          registration_params.merge(user: Current.user, status: "EOI")
        )

        if registration.save
          render json: RegistrationSerializer.new(registration).as_json, status: :created
        else
          # SailingParticipant validates user_id uniqueness scoped to sailing_id,
          # so registering twice lands here as a 422.
          render_invalid(registration)
        end
      end

      def destroy
        registration = Current.user.sailing_participants.find(params[:id])
        registration.destroy
        head :no_content
      end

      private

      # Flat top-level body, e.g. {"comment": "Happy to cook", "climbing": 1}.
      # user_id and status are deliberately not permitted: the member always
      # registers themselves, always as an EOI.
      def registration_params
        params.permit(:comment, :climbing)
      end
    end
  end
end
