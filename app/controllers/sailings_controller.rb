class SailingsController < ApplicationController
  before_action :set_sailing, only: %i[show edit update destroy]

  def index
    @sailings = Sailing.left_joins(:sailing_participants).select("sailings.*, COUNT(sailing_participants.id) AS participants_count").group("sailings.id")
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
    params.require(:sailing).permit(:purpose, :status, :departs_at, :returns_at, :ln_contact, :master, :comments)
  end
end
