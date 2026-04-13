class Sailing < ApplicationRecord
  SAILING_TYPES = %w[Voyage Training Charter Maintenance Special].freeze

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
  validates :sailing_type, inclusion: { in: SAILING_TYPES }, allow_blank: true
  enum :sailing_type, SAILING_TYPES.index_by { |t| t }, scopes: false

  attr_writer :departs_date, :departs_time, :returns_date, :returns_time

  def departs_date = departs_at&.to_date
  def departs_time = departs_at&.strftime("%H:%M")
  def returns_date = returns_at&.to_date
  def returns_time = returns_at&.strftime("%H:%M")
  def voyage_dates
    return "" unless departs_at

    result = "#{departs_date.strftime("%d %b %Y")} - #{departs_time}"
    if returns_at
      result += " to "
      result += "#{returns_date.strftime("%d %b %Y")} - " if returns_date != departs_date
      result += returns_time
    end
    result
  end

  before_validation :combine_datetime_fields

  private

  def combine_datetime_fields
    self.departs_at = Time.zone.parse("#{@departs_date} #{@departs_time}") if @departs_date.present?
    self.returns_at = Time.zone.parse("#{@returns_date} #{@returns_time}") if @returns_date.present?
  end
end
