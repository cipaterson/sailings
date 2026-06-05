class MaintenanceTasksController < ApplicationController
  before_action :set_maintenance_task, only: %i[show edit update destroy]
  before_action :require_maintenance_or_office_staff!, only: %i[new create edit update destroy]

  PER_PAGE = 15

  def in_progress
    base = MaintenanceTask.where(date_fixed: nil).order(date_reported: :asc)

    @current_page = (params[:page] || 1).to_i.clamp(1, Float::INFINITY)
    @total_pages = [ (base.count.to_f / PER_PAGE).ceil, 1 ].max
    @current_page = @current_page.clamp(1, @total_pages)

    @maintenance_tasks = base
                          .limit(PER_PAGE)
                          .offset((@current_page - 1) * PER_PAGE)
  end

  def index
@from_date = if params.key?(:from_date)
                   Date.parse(params[:from_date]) rescue nil
else
                   1.month.ago.to_date
end
    @to_date = Date.parse(params[:to_date]) rescue nil if params[:to_date].present?

    base = MaintenanceTask.all
    base = base.where("date_fixed >= ?", @from_date.beginning_of_day) if @from_date
    base = base.where("date_fixed <= ?", @to_date.end_of_day) if @to_date
    base = base.order(date_fixed: :asc)

    @current_page = (params[:page] || 1).to_i.clamp(1, Float::INFINITY)
    @total_pages = [ (base.count.to_f / PER_PAGE).ceil, 1 ].max
    @current_page = @current_page.clamp(1, @total_pages)

    @maintenance_tasks = base
                          .limit(PER_PAGE)
                          .offset((@current_page - 1) * PER_PAGE)
  end

  def show
  end

  def new
    @maintenance_task = MaintenanceTask.new
    @maintenance_task.state = "Reported"
    @maintenance_task.priority = "Low"
  end

  def create
    @maintenance_task = MaintenanceTask.new(maintenance_task_params)
    if @maintenance_task.save
      redirect_to @maintenance_task, notice: "Maintenance task was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @maintenance_task.update(maintenance_task_params)
      redirect_to safe_return_to(maintenance_tasks_path), notice: "Maintenance task was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @maintenance_task.destroy
    redirect_to maintenance_tasks_path, notice: "Maintenance task was successfully deleted."
  end

  private

  def set_maintenance_task
    @maintenance_task = MaintenanceTask.find(params[:id])
  end

  def require_maintenance_or_office_staff!
    require_role!("maintenance", "office_staff")
  end

  def maintenance_task_params
    params.require(:maintenance_task).permit(:problem_description, :state, :priority, :date_reported, :date_fixed, :who_reported, :who_fixed, :fixed_note, :comments)
  end
end
