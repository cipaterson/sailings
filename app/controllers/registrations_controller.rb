class RegistrationsController < ApplicationController
  def index
    @users_with_assignments = User.select("*").
      joins(:assignments).where("assignments.sailing_id =?", Current.user.id)
  end
end
