class Sailing < ApplicationRecord
  STATUSES = %w[draft active archived].freeze

  has_many :sailing_participants, dependent: :destroy
  has_many :users, through: :sailing_participants

  validates :purpose, presence: true
  validates :status, inclusion: { in: STATUSES }
end
