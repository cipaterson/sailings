class Store::UsersController < Store::BaseController
  before_action :set_user, only: %i[ show edit update destroy ]

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
    # raise "debug"
    if @user.save
      redirect_to store_user_path(@user), status: :see_other, notice: "User has been CREATED"
    else
      render :new, status: :unprocessable_entity, notice: "ththnthnthnth"
    end
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to store_user_path(@user), status: :see_other, notice: "User has been updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    redirect_to store_users_path
  end

  private
    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      # params.expect(user: [ :first_name, :last_name, :email_address, :mobile ])
      params.expect(user: [ :first_name, :last_name, :email_address, :password, :password_confirmation, :mobile ])

    end
end
