class UsersController < ApplicationController
  before_action :set_user, only: %i[show edit update destroy]

  def index
    @users = User.all
  end

  def show
  end

  def new
    @user = User.new
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
  end

  def update
    params_to_update = user_params
    params_to_update = params_to_update.reject { |k, v| k.to_s.in?(%w[password password_confirmation]) && v.blank? }
    if @user.update(params_to_update)
      redirect_to @user, notice: "User was successfully updated."
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

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation,
                                 :first_name, :last_name, :mobile_phone, :home_phone,
                                 :birth_date, :occupation, :membership_type, :sailing_class, :sit_date)
  end
end
