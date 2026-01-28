class Sailing < ApplicationRecord
  has_many :assignments, dependent: :destroy
  validates :name, presence: true
end
