class Assignment < ApplicationRecord
  belongs_to :sailing
  belongs_to :user
  enum :rating, [ :crew, :trainee ]
  enum :registration, [ :eoi, :accepted, :not_required ], default: :eoi

  validates :rating, presence: true
  validates :registration, presence: true
  validates :sailing_id, presence: true
  validates :user_id, presence: true
end
