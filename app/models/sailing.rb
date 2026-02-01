class Sailing < ApplicationRecord
  has_many :assignments, dependent: :destroy
  has_many :users, through: :assignments

  validates :name, presence: true
end
