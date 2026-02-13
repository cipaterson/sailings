class Assignment < ApplicationRecord
  belongs_to :sailing
  belongs_to :user
  enum :rating, [ :crew, :trainee ]
  enum :registration, [ :EoI, :Accepted, :NotRequired ], default: :EoI

  validates :rating, presence: true
  validates :registration, presence: true
  validates :sailing_id, presence: true
  validates :user_id, presence: true
end
