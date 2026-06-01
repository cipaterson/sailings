class Sailing < ApplicationRecord
  SAILING_TYPES    = %w[Sail Maintenance Engineering Other].freeze
  SAILING_STATUSES = %w[draft scheduled closed done].freeze
  TRAINING_TYPES   = %w[MSR SIT1 SIT2].freeze
  CHARTER_STATES   = %w[TBC Confirmed Outstanding Paid].freeze

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
  has_one :charter_contact, -> { where(contact_type: "charter_contact") },
          class_name: "Contact", as: :contactable, dependent: :destroy
  accepts_nested_attributes_for :charter_contact, allow_destroy: true, reject_if: :all_blank


  validates :purpose, presence: true
  validates :sailing_type, presence: true, inclusion: { in: SAILING_TYPES }
  enum :sailing_type, SAILING_TYPES.index_by { |t| t }, scopes: false
  enum :status,   SAILING_STATUSES.index_by { |s| s }, scopes: false
  enum :training,       TRAINING_TYPES.index_by { |t| t },  scopes: false
  enum :charter_state,  CHARTER_STATES.index_by { |s| s },  scopes: false

  monetize :quoted_cost_cents,  allow_nil: true
  monetize :deposit_cents,       allow_nil: true
  monetize :final_amount_cents,  allow_nil: true

  attr_writer :departs_date, :departs_time, :returns_date, :returns_time

  def display_name
    parts = [purpose]
    parts << departs_at.strftime("%d %b %Y") if departs_at
    parts << "(#{charterer})" if charterer.present?
    parts.join(" – ")
  end

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
  before_validation :auto_set_status

  private

  def auto_set_status
    self.status = "scheduled" if departs_at.present? && status == "draft"
  end

  def combine_datetime_fields
    self.departs_at = Time.zone.parse("#{@departs_date} #{@departs_time}") if @departs_date.present?
    self.returns_at = Time.zone.parse("#{@returns_date} #{@returns_time}") if @returns_date.present?
  end
end
