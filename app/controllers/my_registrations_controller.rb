class MyRegistrationsController < ApplicationController
  def index
    @sailings_with_assignments = Sailing.select("*").
      joins(:assignments).where("assignments.user_id =?", Current.user.id)
  end
end
