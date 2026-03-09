class SailingParticipantsController < ApplicationController
  before_action :set_sailing, only: [:index, :create, :update]

  def index
    @sailing_participants = @sailing.sailing_participants.includes(:user)
    @sailing_participant = SailingParticipant.new
  end

  def create
    @sailing_participant = @sailing.sailing_participants.build(sailing_participant_params)
    if @sailing_participant.save
      redirect_to sailing_sailing_participants_path(@sailing), notice: "Participant was successfully added."
    else
      @sailing_participants = @sailing.sailing_participants.includes(:user)
      render :index, status: :unprocessable_entity
    end
  end

  def update
    @sailing_participant = @sailing.sailing_participants.find(params[:id])
    old_status = @sailing_participant.status
    if @sailing_participant.update(sailing_participant_params)
      if old_status != @sailing_participant.status
        SailingParticipantMailer.status_changed(@sailing_participant, old_status).deliver_later
      end
      redirect_to sailing_sailing_participants_path(@sailing), notice: "Status was successfully updated."
    else
      @sailing_participants = @sailing.sailing_participants.includes(:user)
      @sailing_participant = SailingParticipant.new
      render :index, status: :unprocessable_entity
    end
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
