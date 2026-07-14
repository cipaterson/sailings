module Api
  module V1
    class SailingsController < BaseController
      # Upcoming scheduled voyages, soonest first. Mirrors the default view of
      # SailingsController#index (from today forward), narrowed to "scheduled"
      # since drafts and closed voyages are not something a member can act on.
      def index
        sailings = Sailing.where(status: "scheduled")
                          .where(departs_at: Time.current.beginning_of_day..)
                          .left_joins(:sailing_participants)
                          .select("sailings.*, COUNT(sailing_participants.id) AS participants_count")
                          .group("sailings.id")
                          .order("sailings.departs_at ASC")

        # The member's own registration for each voyage, so the app can show
        # "Register" or "Registered" without a second round trip.
        mine = Current.user.sailing_participants
                      .where(sailing_id: sailings.map(&:id))
                      .index_by(&:sailing_id)

        render json: sailings.map { |s|
          SailingSerializer.new(s).as_json.merge(
            my_registration: mine[s.id] && {
              id: mine[s.id].id,
              status: mine[s.id].status
            }
          )
        }
      end

      def show
        sailing = Sailing.find(params[:id])
        mine = Current.user.sailing_participants.find_by(sailing_id: sailing.id)

        render json: SailingSerializer.new(sailing).as_json.merge(
          my_registration: mine && { id: mine.id, status: mine.status }
        )
      end
    end
  end
end
