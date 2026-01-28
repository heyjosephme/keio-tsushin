class Enrollment < ApplicationRecord
  STATUSES = %w[planned report_submitted exam_applied completed].freeze

  belongs_to :user, optional: true

  validates :course_key, presence: true, uniqueness: { scope: :user_id, message: "already enrolled" }
  validates :season_key, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :for_season, ->(season_key) { where(season_key: season_key) }
  scope :for_course, ->(course_key) { where(course_key: course_key) }
  scope :planned, -> { where(status: "planned") }
  scope :completed, -> { where(status: "completed") }
  scope :in_progress, -> { where(status: %w[report_submitted exam_applied]) }
  scope :by_category, ->(category) { where("1=1") } # Filtering happens in Ruby since category is from Course

  # Class methods for credit calculations
  def self.total_credits_by_status(status_scope)
    status_scope.sum { |enrollment| enrollment.credits || 0 }
  end

  def self.credit_stats
    all_enrollments = all.to_a
    {
      completed: total_credits_by_status(all_enrollments.select { |e| e.status == "completed" }),
      in_progress: total_credits_by_status(all_enrollments.select { |e| %w[report_submitted exam_applied].include?(e.status) }),
      planned: total_credits_by_status(all_enrollments.select { |e| e.status == "planned" }),
      total: total_credits_by_status(all_enrollments)
    }
  end

  def self.credits_by_category
    all_enrollments = all.to_a
    categories = %w[required elective foreign_language physical_education]

    categories.each_with_object({}) do |category, hash|
      enrollments_in_category = all_enrollments.select { |e| e.category == category }
      hash[category] = {
        completed: total_credits_by_status(enrollments_in_category.select { |e| e.status == "completed" }),
        in_progress: total_credits_by_status(enrollments_in_category.select { |e| %w[report_submitted exam_applied].include?(e.status) }),
        planned: total_credits_by_status(enrollments_in_category.select { |e| e.status == "planned" }),
        total: total_credits_by_status(enrollments_in_category)
      }
    end
  end

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
