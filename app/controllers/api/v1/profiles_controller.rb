module Api
  module V1
    class ProfilesController < BaseController
      # Always the signed-in member's own record — there is no :id to tamper with.
      def show
        render json: ProfileSerializer.new(Current.user).as_json
      end
    end
  end
end
