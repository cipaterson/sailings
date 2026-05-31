class SailingsController < ApplicationController
  before_action :set_sailing, only: %i[show edit update destroy manifest set_status]
  before_action :require_office_staff_or_crewing_operator!, only: %i[new create edit update destroy manifest set_status]

  PER_PAGE = 15

  def index
    @status_filter = params[:status].presence

    if @status_filter
      base = Sailing.where(status: @status_filter)
    else
      @from_date = if params.key?(:from_date)
                     Date.parse(params[:from_date]) rescue nil
                   else
                     Date.today
                   end
      @to_date = Date.parse(params[:to_date]) rescue nil if params[:to_date].present?

      base = Sailing.all
      base = base.where("departs_at >= ?", @from_date.beginning_of_day) if @from_date
      base = base.where("departs_at <= ?", @to_date.end_of_day) if @to_date
    end

    filtered = base.left_joins(:sailing_participants)
                   .select("sailings.*, COUNT(sailing_participants.id) AS participants_count")
                   .group("sailings.id")
                   .order("sailings.departs_at ASC")

    respond_to do |format|
      format.html do
        @current_page = (params[:page] || 1).to_i.clamp(1, Float::INFINITY)
        @total_pages  = [ (base.count.to_f / PER_PAGE).ceil, 1 ].max
        @current_page = @current_page.clamp(1, @total_pages)
        @sailings = filtered.limit(PER_PAGE).offset((@current_page - 1) * PER_PAGE)
        @my_participants = Current.user.sailing_participants
                                 .where(sailing_id: @sailings.map(&:id))
                                 .index_by(&:sailing_id)
      end
      format.csv do
        csv_data = CSV.generate(headers: true) do |csv|
          csv << [ "Day", "Date", "Purpose", "Charterer", "Depart Time", "Return Date", "Return Time", "LN Contact", "Master", "Crew", "Comments" ]
          filtered.each do |s|
            csv << [
              s.departs_at&.strftime("%a"),
              s.departs_at&.to_date,
              s.purpose,
              s.charterer,
              s.departs_at&.strftime("%H:%M"),
              (s.returns_at&.to_date unless s.returns_at&.to_date == s.departs_at&.to_date),
              s.returns_at&.strftime("%H:%M"),
              s.ln_contact,
              s.master,
              s.participants_count,
              s.comments
            ]
          end
        end
        send_data csv_data, filename: "voyages-#{Date.today}.csv", type: "text/csv"
      end
    end
  end

  def calendar
    @view  = params[:view].presence_in(%w[month week day]) || "month"
    @year  = (params[:year]  || Date.today.year).to_i
    @month = (params[:month] || Date.today.month).to_i
    @day   = (params[:day]   || Date.today.day).to_i
    @date  = Date.new(@year, @month, @day) rescue Date.new(@year, @month, 1)

    first, last = case @view
    when "week"
      week_start = @date.beginning_of_week(:monday)
      [ week_start, week_start + 6.days ]
    when "day"
      [ @date, @date ]
    else
      [ Date.new(@year, @month, 1), Date.new(@year, @month, 1).end_of_month ]
    end

    @sailings = Sailing.where("departs_at <= ?", last.end_of_day)
                       .where("returns_at >= ? OR (returns_at IS NULL AND departs_at >= ?)",
                              first.beginning_of_day, first.beginning_of_day)
                       .order(:departs_at)

    @my_participants = Current.user.sailing_participants
                             .where(sailing_id: @sailings.map(&:id))
                             .index_by(&:sailing_id)
  end

  def show
  end

  def new
    @sailing = Sailing.new
    @sailing.build_charter_contact
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
    @sailing.charter_contact || @sailing.build_charter_contact
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

  def set_status
    @sailing.update!(status: params[:status])
    redirect_back fallback_location: sailings_path
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
    params.require(:sailing).permit(
      :purpose, :sailing_type, :status, :departs_date, :departs_time, :returns_date, :returns_time,
      :ln_contact, :master, :comments, :charterer, :passenger_count, :additional_details, :engineer,
      charter_contact_attributes: [
        :id, :full_name, :email_address, :work_phone, :mobile,
        :address1, :address2, :city, :state, :postcode
      ]
    )
  end
end
