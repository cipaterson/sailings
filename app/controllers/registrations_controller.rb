class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_registration_path, alert: "Try again later." }

  def new
    @user = User.new
    @user.build_contact
    @user.build_next_of_kin
  end

  def create
    @user = User.new(registration_params)
    if @user.save
      # Account is created pending (approved_at is nil). No session is started;
      # office staff must approve it after confirming payment before login works.
      MembershipMailer.new_application(@user).deliver_later
      MembershipMailer.application_received(@user).deliver_later
      redirect_to new_session_path,
                  notice: "Thanks for applying! Your membership is pending approval — we'll be in touch once it's confirmed."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  # Deliberately narrow: never permit roles, fees, qualifications, membership_type,
  # or approved_at on this public endpoint (privilege-escalation risk).
  def registration_params
    params.require(:user).permit(
      :email_address, :password, :password_confirmation,
      :first_name, :last_name, :birth_date, :occupation,
      contact_attributes: [
        :full_name, :email_address, :work_phone, :mobile,
        :address1, :address2, :city, :state, :postcode
      ],
      next_of_kin_attributes: [
        :full_name, :email_address, :work_phone, :mobile,
        :address1, :address2, :city, :state, :postcode
      ]
    )
  end
end
