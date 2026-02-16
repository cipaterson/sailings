class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  has_many :assignments, dependent: :destroy
  has_many :sailings, through: :assignments

  attr_readonly :admin

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :first_name, :last_name, presence: true

  generates_token_for :email_confirmation, expires_in: 7.days do
    unconfirmed_email
  end

  def confirm_email
    update(email_address: unconfirmed_email, unconfirmed_email: nil)
  end

  def full_name
    "#{first_name} #{last_name}"
  end
end
