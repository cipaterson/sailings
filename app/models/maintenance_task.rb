class MaintenanceTask < ApplicationRecord
  STATES = %w[Reported Open Closed].freeze
  PRIORITIES = %w[Low Medium High].freeze

  validates :problem_description, presence: true
  validates :date_reported, presence: true
  validates :who_reported, presence: true
  validates :state, inclusion: { in: STATES }, allow_blank: true
  validates :priority, inclusion: { in: PRIORITIES }, allow_blank: true
  enum :state, STATES.index_by { |t| t }, scopes: false
  enum :priority, PRIORITIES.index_by { |t| t }, scopes: false

  def who_reported_name
    User.find_by(id: who_reported)&.full_name || who_reported
  end

  def who_fixed_name
    User.find_by(id: who_fixed)&.full_name || who_fixed
  end
end
