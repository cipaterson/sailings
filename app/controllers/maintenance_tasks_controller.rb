class MaintenanceTasksController < ApplicationController
  before_action :set_maintenance_task, only: %i[show edit update destroy]

  def index
    @maintenance_tasks = MaintenanceTask.order("date_fixed ASC")
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
      redirect_to @maintenance_task, notice: "Maintenance task was successfully updated."
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

  def maintenance_task_params
    params.require(:maintenance_task).permit(:problem_description, :state, :priority, :date_reported, :date_fixed, :who_reported, :who_fixed, :fixed_note, :comments)
  end
end
