class UsersController < ApplicationController
  before_action :set_user, only: %i[show edit update destroy confirm_delete disable]
  before_action :require_office_staff!, only: %i[index new create destroy confirm_delete disable]
  before_action :require_self_or_office_staff!, only: %i[show edit update]

  PER_PAGE = 15

  def index
    @disabled_filter = params[:disabled].present?

    if @disabled_filter
      base = User.where(roles_mask: 0)
    else
      base = User.where("roles_mask > 0")
      @selected_roles = Array(params[:roles]).select { |r| User::ROLES.include?(r) }
      @search = params[:search].presence

      if @selected_roles.any?
        mask = @selected_roles.sum { |r| 2**User::ROLES.index(r) }
        base = base.where("roles_mask & ? != 0", mask)
      end

      if @search
        if @search.match?(/\A\d+\z/)
          base = base.where("fees_due >= ?", @search.to_i)
        else
          term = "%#{@search}%"
          base = base.where("(first_name || ' ' || last_name) LIKE ? OR email_address LIKE ?", term, term)
        end
      end
    end

    respond_to do |format|
      format.html do
        @current_page = (params[:page] || 1).to_i.clamp(1, Float::INFINITY)
        @total_pages  = [ (base.count.to_f / PER_PAGE).ceil, 1 ].max
        @current_page = @current_page.clamp(1, @total_pages)
        @users = base.order(:last_name, :first_name).limit(PER_PAGE).offset((@current_page - 1) * PER_PAGE)
      end
      format.csv do
        @users = base.order(:last_name, :first_name)
        csv_data = CSV.generate(headers: true) do |csv|
          csv << [ "Name", "Email", "Mobile", "Membership Type", "Fees Paid", "Fees Due", "Roles" ]
          @users.each do |u|
            csv << [ u.full_name, u.email_address, u.contact&.mobile, u.membership_type, u.fees_paid, u.fees_due, u.roles.join(", ") ]
          end
        end
        send_data csv_data, filename: "members-#{Date.today}.csv", type: "text/csv"
      end
    end
  end

  def show
  end

  def new
    @user = User.new
    @user.build_contact
    @user.build_next_of_kin
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to @user, notice: "User was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @user.contact || @user.build_contact
    @user.next_of_kin || @user.build_next_of_kin
  end

  def update
    params_to_update = user_params
    params_to_update = params_to_update.reject { |k, v| k.to_s.in?(%w[password password_confirmation]) && v.blank? }
    if @user.update(params_to_update)
      redirect_to safe_return_to(users_path), notice: "User was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    redirect_to users_path, notice: "User was successfully deleted."
  end

  def confirm_delete
    if @user == Current.user
      redirect_to edit_user_path(@user), alert: "You cannot delete your own account."
    end
  end

  def disable
    if @user == Current.user
      redirect_to edit_user_path(@user), alert: "You cannot disable your own account."
      return
    end
    @user.update!(roles_mask: 0)
    @user.sessions.destroy_all
    redirect_to users_path, notice: "#{@user.full_name} has been disabled."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def require_self_or_office_staff!
    unless @user == Current.user || Current.user&.has_role?("office_staff")
      redirect_to root_path, alert: "You are not authorized to perform this action."
    end
  end

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation,
                                 :first_name, :last_name, :birth_date, :occupation,
                                 :membership_type, :sailing_class,
                                 :fees_due, :days_sailed, :date_joined, :last_sailed,
                                 :fees_paid, :rcpt_number, :sit2_date, :sit_date,
                                 :knots_on, :marine_safety_refresher_on,
                                 :ess_qualification, :ess_issued_on, :ess_expires_on,
                                 :med_qualification, :med_issued_on, :med_expires_on,
                                 :wwvp_qualification, :wwvp_issued_on, :wwvp_expires_on,
                                 :first_aid_qualification, :first_aid_issued_on, :first_aid_expires_on,
                                 :coxswain_qualification, :coxswain_issued_on, :coxswain_expires_on,
                                 :food_handling_qualification, :food_handling_issued_on, :food_handling_expires_on,
                                 roles: [],
                                 contact_attributes: [
                                   :id, :full_name, :email_address, :work_phone, :mobile,
                                   :address1, :address2, :city, :state, :postcode
                                 ],
                                 next_of_kin_attributes: [
                                   :id, :full_name, :email_address, :work_phone, :mobile,
                                   :address1, :address2, :city, :state, :postcode
                                 ])
  end
end
