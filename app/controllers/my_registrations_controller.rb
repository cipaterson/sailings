class MyRegistrationsController < ApplicationController
  def show
    @sailing_participants = Current.user.sailing_participants.includes(:sailing)
  end
end
