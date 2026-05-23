class UsersController < ApplicationController
  before_action :set_user, only: %i[show edit update destroy]
  before_action :require_office_staff!, only: %i[index new create destroy]
  before_action :require_self_or_office_staff!, only: %i[show edit update]

  def index
    @users = User.all
    @selected_roles = Array(params[:roles]).select { |r| User::ROLES.include?(r) }
    @search = params[:search].presence

    if @selected_roles.any?
      mask = @selected_roles.sum { |r| 2**User::ROLES.index(r) }
      @users = @users.where("roles_mask & ? != 0", mask)
    end

    if @search
      term = "%#{@search}%"
      @users = @users.where("(first_name || ' ' || last_name) LIKE ? OR email_address LIKE ?", term, term)
    end

    respond_to do |format|
      format.html
      format.csv do
        csv_data = CSV.generate(headers: true) do |csv|
          csv << [ "Name", "Email", "Mobile", "Membership Type", "Roles" ]
          @users.each do |u|
            csv << [ u.full_name, u.email_address, u.contact&.mobile, u.membership_type, u.roles.join(", ") ]
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
      redirect_to users_path, notice: "User was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    redirect_to users_path, notice: "User was successfully deleted."
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
