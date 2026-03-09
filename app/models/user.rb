class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :sailing_participants, dependent: :destroy
  has_many :sailings, through: :sailing_participants

  MEMBERSHIP_TYPES = %w[Life Family Individual Junior].freeze

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def full_name
    "#{first_name} #{last_name}".strip.presence || email_address
  end

  validates :membership_type, inclusion: { in: MEMBERSHIP_TYPES }, allow_blank: true
end
