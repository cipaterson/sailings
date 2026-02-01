class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  has_many :assignments, dependent: :destroy
  has_many :sailings, through: :assignments

  attr_readonly :admin

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :first_name, :last_name, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end
end
