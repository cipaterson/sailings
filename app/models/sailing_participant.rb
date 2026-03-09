class SailingParticipant < ApplicationRecord
  STATUSES = %w[EOI Accepted Not-required].freeze

  belongs_to :sailing
  belongs_to :user

  validates :sailing_id, :user_id, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :user_id, uniqueness: { scope: :sailing_id }
end
