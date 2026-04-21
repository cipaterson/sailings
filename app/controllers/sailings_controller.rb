class SailingsController < ApplicationController
  before_action :set_sailing, only: %i[show edit update destroy manifest]
  before_action :require_office_staff_or_crewing_operator!, only: %i[new create edit update destroy manifest]

  PER_PAGE = 15

  def index
    @from_date = if params.key?(:from_date)
                   Date.parse(params[:from_date]) rescue nil
    else
                   Date.today
    end
    @to_date = Date.parse(params[:to_date]) rescue nil if params[:to_date].present?

    base = Sailing.all
    base = base.where("departs_at >= ?", @from_date.beginning_of_day) if @from_date
    base = base.where("departs_at <= ?", @to_date.end_of_day) if @to_date

    @current_page = (params[:page] || 1).to_i.clamp(1, Float::INFINITY)
    @total_pages  = [ (base.count.to_f / PER_PAGE).ceil, 1 ].max
    @current_page = @current_page.clamp(1, @total_pages)

    @sailings = base.left_joins(:sailing_participants)
                    .select("sailings.*, COUNT(sailing_participants.id) AS participants_count")
                    .group("sailings.id")
                    .order("sailings.departs_at ASC")
                    .limit(PER_PAGE)
                    .offset((@current_page - 1) * PER_PAGE)

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

  def manifest
    participants = @sailing.sailing_participants.includes(:user).order("users.last_name, users.first_name")
    pdf = SailingManifestPdf.new(@sailing, participants)
    send_data pdf.render,
              filename: "manifest-#{@sailing.id}.pdf",
              type: "application/pdf",
              disposition: "inline"
  end

  def update
    if @sailing.update(sailing_params)
      redirect_to sailings_path, notice: "Sailing was successfully updated."
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
    params.require(:sailing).permit(:purpose, :sailing_type, :departs_date, :departs_time, :returns_date, :returns_time, :ln_contact, :master, :comments, :charterer, :passenger_count, :additional_details, :engineer, :charter_full_name, :charter_email_address, :charter_work_phone, :charter_mobile, :charter_address1, :charter_address2, :charter_city, :charter_state, :charter_postcode)
  end
end
