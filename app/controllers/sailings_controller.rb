class SailingsController < ApplicationController
  before_action :set_sailing, only: %i[show edit update destroy]

  def index
    @sailings = Sailing.left_joins(:sailing_participants).select("sailings.*, COUNT(sailing_participants.id) AS participants_count").group("sailings.id")
    @my_participants = Current.user.sailing_participants
                             .where(sailing_id: @sailings.map(&:id))
                             .index_by(&:sailing_id)
  end

  def show
  end

  def new
    @sailing = Sailing.new
  end

  def create
    @sailing = Sailing.new(sailing_params)
    if @sailing.save
      redirect_to @sailing, notice: "Sailing was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @sailing.update(sailing_params)
      redirect_to @sailing, notice: "Sailing was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @sailing.destroy
    redirect_to sailings_path, notice: "Sailing was successfully deleted."
  end

  private

  def set_sailing
    @sailing = Sailing.find(params[:id])
  end

  def sailing_params
    params.require(:sailing).permit(:purpose, :status, :departs_date, :departs_time, :returns_date, :returns_time, :ln_contact, :master, :comments, :charterer, :passenger_count, :additional_details, :engineer, :charter_full_name, :charter_email_address, :charter_work_phone, :charter_mobile, :charter_address1, :charter_address2, :charter_city, :charter_state, :charter_postcode)
  end
end
