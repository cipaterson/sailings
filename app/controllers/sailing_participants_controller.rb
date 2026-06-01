class SailingParticipantsController < ApplicationController
  before_action :set_sailing, only: [ :index, :create, :bulk_update, :new, :sms_accepted ]
  before_action :set_sailing_participant, only: [ :edit, :update, :destroy ]
  before_action :require_office_staff_or_crewing_operator!, only: [ :index, :bulk_update, :sms_accepted ]

  def index
    @sailing_participants = @sailing.sailing_participants.includes(:user)
    @sailing_participant = SailingParticipant.new

    respond_to do |format|
      format.html
      format.csv do
        accepted = @sailing_participants.select { |sp| sp.status == "Accepted" }
        csv_data = CSV.generate(headers: true) do |csv|
          csv << [ "Name", "Email", "Mobile", "ESS", "Class", "MED", "WWVP Expires", "Marine Safety Refresher", "Status" ]
          accepted.each do |sp|
            u = sp.user
            csv << [ u.full_name, u.email_address, u.contact&.mobile,
                     u.ess_qualification, u.sailing_class, u.med_qualification,
                     u.wwvp_expires_on, u.marine_safety_refresher_on, sp.status ]
          end
        end
        send_data csv_data,
                  filename: "crew-#{@sailing.id}-#{Date.today}.csv",
                  type: "text/csv"
      end
    end
  end

  def new
    @sailing_participant = @sailing.sailing_participants.build(user_id: Current.user.id, status: "EOI")
  end

  def edit
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
      if resolved_params[:user_id].to_s == Current.user.id.to_s
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

  def update
    if @sailing_participant.update(sailing_participant_params)
      redirect_to sailings_path, notice: "Registration updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def bulk_update
    statuses = params[:statuses] || {}
    attended = params[:attended] || {}
    statuses.each do |id, status|
      participant = @sailing.sailing_participants.find(id)
      old_status   = participant.status
      old_attended = participant.attended.to_i
      attended_value = attended[id] == "1" ? 1 : 0
      if participant.update(status: status, attended: attended_value)
        if old_status != participant.status
          SailingParticipantMailer.status_changed(participant, old_status).deliver_later
        end
        if @sailing.sailing_type == "Sail" && attended_value == 1 && old_attended != 1
          participant.user.update!(
            days_sailed: participant.user.days_sailed.to_i + 1,
            last_sailed: @sailing.departs_at&.to_date
          )
        end
        if @sailing.training.present? && attended_value == 1 && old_attended != 1
          training_field = { "MSR" => :marine_safety_refresher_on,
                             "SIT1" => :sit_date,
                             "SIT2" => :sit2_date }[@sailing.training]
          participant.user.update!(training_field => @sailing.departs_at&.to_date) if training_field
        end
      end
    end
    if params[:close_sailing] == "1"
      @sailing.update!(status: "closed")
    elsif params[:reopen_sailing] == "1"
      @sailing.update!(status: "scheduled")
    end
    redirect_to sailing_sailing_participants_path(@sailing), notice: "Participants were successfully updated."
  end

  def destroy
    @sailing_participant.destroy
    redirect_to sailings_path, notice: "Registration was successfully cancelled."
  end

  def sms_accepted
    message = params[:sms_message].to_s.strip
    if message.blank?
      redirect_to sailing_sailing_participants_path(@sailing), alert: "Message cannot be blank."
      return
    end

    mobiles = @sailing.sailing_participants
                      .includes(user: :contact)
                      .where(status: "Accepted")
                      .filter_map { |sp| sp.user.contact&.mobile.presence }

    if mobiles.empty?
      redirect_to sailing_sailing_participants_path(@sailing), alert: "No mobile numbers found for Accepted participants."
      return
    end

    SendSmsBatchJob.perform_later(mobiles: mobiles, message: message)
    redirect_to sailing_sailing_participants_path(@sailing), notice: "SMS queued for #{mobiles.size} accepted participant(s)."
  end

  private

  def set_sailing
    @sailing = Sailing.find(params[:sailing_id])
  end

  def set_sailing_participant
    @sailing_participant = Current.user.sailing_participants.find(params[:id])
  end

  def sailing_participant_params
    params.require(:sailing_participant).permit(:user_id, :status, :comment, :climbing)
  end
end
