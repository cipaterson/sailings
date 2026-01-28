class Assignment < ApplicationRecord
  belongs_to :sailing
  belongs_to :user
  # xxx should this be role?
  enum rating: { crew: 0, trainee: 1 }
end
