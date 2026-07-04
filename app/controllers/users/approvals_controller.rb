class Users::ApprovalsController < ApplicationController
  before_action :require_office_staff!

  def create
    user = User.find(params[:user_id])

    if user.approved?
      redirect_back fallback_location: users_path(pending: true),
                    alert: "#{user.full_name} is already approved."
      return
    end

    unless user.fees_paid.present? && user.membership_type.present?
      redirect_to edit_user_path(user, tab: "membership"),
                  alert: "Set Fees Paid and Membership Type before approving #{user.full_name}."
      return
    end

    user.roles = [ "member" ] if user.roles.empty?
    user.update!(approved_at: Time.current)
    redirect_to users_path(pending: true),
                notice: "#{user.full_name} has been approved."
  end
end
