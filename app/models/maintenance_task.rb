class MaintenanceTask < ApplicationRecord
  validates :problem_description, presence: true
  validates :date_reported, presence: true
  validates :who_reported, presence: true

  def who_reported_name
    User.find_by(id: who_reported)&.full_name || who_reported
  end

  def who_fixed_name
    User.find_by(id: who_fixed)&.full_name || who_fixed
  end
end
