class SailingParticipantsController < ApplicationController
  before_action :set_sailing, only: [:index, :create, :bulk_update]
  before_action :require_office_staff_or_crewing_operator!, only: [:index, :bulk_update]

  def index
    @sailing_participants = @sailing.sailing_participants.includes(:user)
    @sailing_participant = SailingParticipant.new
  end

  def create
    resolved_params = sailing_participant_params
    adding_other_user = resolved_params[:user_id].present? && resolved_params[:user_id].to_s != Current.user.id.to_s
    if adding_other_user && !Current.user&.has_role?("office_staff") && !Current.user&.has_role?("crewing_operator")
      redirect_to root_path, alert: "You are not authorized to perform this action."
      return
    end
    resolved_params = resolved_params.merge(user_id: Current.user.id) if resolved_params[:user_id].blank?
    @sailing_participant = @sailing.sailing_participants.build(resolved_params)
    if @sailing_participant.save
      if resolved_params[:user_id] == Current.user.id
        redirect_to sailings_path, notice: "You have been registered for this sailing."
      else
        SailingParticipantMailer.status_changed(@sailing_participant, nil).deliver_later
        redirect_to sailing_sailing_participants_path(@sailing), notice: "Crew member was successfully added."
      end
    else
      @sailing_participants = @sailing.sailing_participants.includes(:user)
      render :index, status: :unprocessable_entity
    end
  end

  def bulk_update
    statuses = params[:statuses] || {}
    statuses.each do |id, status|
      participant = @sailing.sailing_participants.find(id)
      old_status = participant.status
      if participant.update(status: status)
        if old_status != participant.status
          SailingParticipantMailer.status_changed(participant, old_status).deliver_later
        end
      end
    end
    redirect_to sailing_sailing_participants_path(@sailing), notice: "Participants were successfully updated."
  end

  def destroy
    @sailing_participant = Current.user.sailing_participants.find(params[:id])
    @sailing_participant.destroy
    redirect_to my_registrations_path, notice: "Registration was successfully cancelled."
  end

  private

  def set_sailing
    @sailing = Sailing.find(params[:sailing_id])
  end

  def sailing_participant_params
    params.require(:sailing_participant).permit(:user_id, :status)
  end
end
