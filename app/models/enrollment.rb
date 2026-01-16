class Enrollment < ApplicationRecord
  STATUSES = %w[planned report_submitted exam_applied completed].freeze

  validates :course_key, presence: true
  validates :season_key, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :for_season, ->(season_key) { where(season_key: season_key) }
  scope :for_course, ->(course_key) { where(course_key: course_key) }
  scope :planned, -> { where(status: "planned") }
  scope :completed, -> { where(status: "completed") }

  def course
    Course.find(course_key)
  end

  def season
    Season.find(season_key)
  end

  def move_to_season!(new_season_key)
    update!(season_key: new_season_key)
  end

  def status_label
    status.to_s.titleize.gsub("_", " ")
  end

  # Delegate to course for convenience
  delegate :name, :name_ja, :credits, :category, to: :course, allow_nil: true
end
