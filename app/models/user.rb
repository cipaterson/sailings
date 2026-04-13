class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :sailing_participants, dependent: :destroy
  has_many :sailings, through: :sailing_participants

  MEMBERSHIP_TYPES = %w[Life Family Individual Junior].freeze
  ROLES = %w[member office_staff crewing_operator trainer purser maintenance].freeze

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def full_name
    "#{first_name} #{last_name}".strip.presence || email_address
  end

  validates :membership_type, inclusion: { in: MEMBERSHIP_TYPES }, allow_blank: true

  PASSWORD_COMPLEXITY = {
    /[A-Z]/         => "one uppercase letter",
    /[a-z]/         => "one lowercase letter",
    /\d/            => "one digit",
    /[^A-Za-z0-9]/ => "one special character"
  }.freeze

  validate :password_complexity, if: -> { password.present? }

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

  private

  def password_complexity
    errors.add(:password, "must be at least 8 characters") if password.length < 8
    PASSWORD_COMPLEXITY.each do |pattern, requirement|
      errors.add(:password, "must contain at least #{requirement}") unless password.match?(pattern)
    end
  end
end
