class Assignment < ApplicationRecord
  belongs_to :sailing
  belongs_to :user
  enum :rating, [ :crew, :trainee ]

  validates :rating, presence: true
  validates :sailing_id, presence: true
  validates :user_id, presence: true
end
