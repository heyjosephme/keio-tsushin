class Deadline < ApplicationRecord
  validates :course_name, presence: true
  validates :deadline_date, presence: true
  validates :deadline_type, presence: true, inclusion: { in: %w[report exam] }

  scope :upcoming, -> { where("deadline_date >= ?", Date.today).order(:deadline_date) }
  scope :past, -> { where("deadline_date < ?", Date.today).order(deadline_date: :desc) }
end
