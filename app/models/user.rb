class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :sailing_participants, dependent: :destroy
  has_many :sailings, through: :sailing_participants

  MEMBERSHIP_TYPES = %w[Life Family Individual Junior].freeze
  ROLES = %w[member office_staff crewing_operator trainer purser].freeze

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def full_name
    "#{first_name} #{last_name}".strip.presence || email_address
  end

  validates :membership_type, inclusion: { in: MEMBERSHIP_TYPES }, allow_blank: true

  # Bitmask role methods
  def roles
    ROLES.select { |r| roles_mask & 2**ROLES.index(r) != 0 }
  end

  def roles=(selected)
    self.roles_mask = (Array(selected).map(&:to_s) & ROLES).sum { |r| 2**ROLES.index(r) }
  end

  def has_role?(role)
    roles.include?(role.to_s)
  end

  ROLES.each do |role|
    define_method(:"#{role}?") { has_role?(role) }
  end

  def admin?
    office_staff? || crewing_operator?
  end

  scope :with_role, ->(role) {
    where("roles_mask & ? != 0", 2**ROLES.index(role.to_s))
  }
end
