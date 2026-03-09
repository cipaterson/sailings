class Sailing < ApplicationRecord
  STATUSES = %w[draft active archived].freeze

  AUSTRALIAN_STATES = [
    "Australian Capital Territory",
    "New South Wales",
    "Northern Territory",
    "Queensland",
    "South Australia",
    "Tasmania",
    "Victoria",
    "Western Australia"
  ].freeze

  has_many :sailing_participants, dependent: :destroy
  has_many :users, through: :sailing_participants

  validates :purpose, presence: true
  validates :status, inclusion: { in: STATUSES }

  attr_writer :departs_date, :departs_time, :returns_date, :returns_time

  def departs_date = departs_at&.to_date
  def departs_time = departs_at&.strftime("%H:%M")
  def returns_date = returns_at&.to_date
  def returns_time = returns_at&.strftime("%H:%M")

  before_validation :combine_datetime_fields

  private

  def combine_datetime_fields
    self.departs_at = Time.zone.parse("#{@departs_date} #{@departs_time}") if @departs_date.present?
    self.returns_at = Time.zone.parse("#{@returns_date} #{@returns_time}") if @returns_date.present?
  end
end
