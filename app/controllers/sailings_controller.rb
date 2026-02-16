class SailingsController < ApplicationController
  before_action :set_sailing, only: %i[ show edit update destroy registration ]
  def index
    @sailings = Sailing.all
  end
  def show
  end
  def new
    @sailing = Sailing.new
  end
  def create
    @sailing = Sailing.new(sailing_params)
    # raise "sailing debug"
    if @sailing.save
      redirect_to @sailing
    else
      render :new, status: :unprocessable_entity
    end
  end
  def edit
  end
  def update
    if @sailing.update(sailing_params)
      redirect_to @sailing
    else
      render :edit, status: :unprocessable_entity
    end
  end
  def destroy
    @sailing.destroy
    redirect_to sailings_path
  end

  def registration
    @users_with_assignments = User.select("*").
      joins(:assignments).where("assignments.sailing_id =?", @sailing.id)
  end

  private
    def set_sailing
      @sailing = Sailing.find(params[:id])
    end

    def sailing_params
      params.expect(sailing: [ :name, :comments, :start_date, :return_date ])
    end
end
