class AssignmentsController < ApplicationController
  before_action :set_assignment, only: %i[ show edit update destroy ]
  before_action :set_sailing, only: %i[ new edit ]

  def index
    # For debug purposes
    @assignments = Assignment.all
  end

  def new
    @assignment = Assignment.new
  end

  def create
    @assignment = Assignment.new(user_id: Current.user.id,
      sailing_id: params[:assignment][:sailing_id], rating: params[:assignment][:rating], registration: :eoi)
    if @assignment.save
      redirect_to root_path, notice: "Assignment was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @assignment.update(user_id: Current.user.id,
      sailing_id: params[:assignment][:sailing_id], rating: params[:assignment][:rating])
      redirect_to root_path, notice: "Assignment was successfully updated."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def destroy
    @assignment.destroy
    redirect_to root_path, status: :see_other
  end

  private
    def set_assignment
      @assignment = Assignment.find(params.extract_value(:id))
    end
    def set_sailing
      @sailing = Sailing.find(params[:sailing_id])
    end

    # TODO
    def assignment_params
      params.require(:assignment).permit(:rating, :sailing_id, :user_id, :user)
    end

end
