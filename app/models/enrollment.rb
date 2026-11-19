class Enrollment < ApplicationRecord
  STATUSES = %w[planned report_submitted exam_applied completed].freeze
  CREDITS_REQUIRED = 124 # credits needed to graduate

  # What a course needs next. action is :submit_report, :apply_exam, :take_exam,
  # :record_result (the exam day has passed) or :reschedule (a deadline was missed).
  NextStep = Data.define(:enrollment, :action, :date, :next_status) do
    def days_left(today = Date.today)
      (date - today).to_i
    end
  end

  belongs_to :user, optional: true

  validates :course_key, presence: true, uniqueness: { scope: :user_id }
  validates :season_key, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :for_season, ->(season_key) { where(season_key: season_key) }
  scope :for_course, ->(course_key) { where(course_key: course_key) }
  scope :planned, -> { where(status: "planned") }
  scope :completed, -> { where(status: "completed") }
  scope :in_progress, -> { where(status: %w[report_submitted exam_applied]) }
  scope :by_field, ->(field) { where("1=1") } # Filtering happens in Ruby since field is from Course

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

  def self.credits_by_field
    all_enrollments = all.to_a

    Course::FIELDS.each_with_object({}) do |field, hash|
      enrollments_in_field = all_enrollments.select { |e| e.field == field }
      hash[field] = {
        completed: total_credits_by_status(enrollments_in_field.select { |e| e.status == "completed" }),
        in_progress: total_credits_by_status(enrollments_in_field.select { |e| %w[report_submitted exam_applied].include?(e.status) }),
        planned: total_credits_by_status(enrollments_in_field.select { |e| e.status == "planned" }),
        total: total_credits_by_status(enrollments_in_field)
      }
    end
  end

  def course
    Course.find(course_key)
  end

  def season
    Season.find(season_key)
  end

  # nil when the course is completed or its season is unknown
  def next_step(today = Date.today)
    return if status == "completed" || season.nil?

    action, date = case status
    when "planned" then [ :submit_report, season.report_deadline ]
    when "report_submitted" then [ :apply_exam, season.application_deadline ]
    else [ :take_exam, exam_date ]
    end
    action = (action == :take_exam ? :record_result : :reschedule) if date < today

    NextStep.new(enrollment: self, action: action, date: date, next_status: STATUSES[STATUSES.index(status) + 1])
  end

  # The day of this course's exam slot; the first exam day if it has no exam group
  def exam_date
    slot = ExamTimetable.slot_for(group: course&.exam_group, season: season)
    slot&.day == "sunday" ? season.exam_end : season.exam_start
  end

  def move_to_season!(new_season_key)
    update!(season_key: new_season_key)
  end

  def status_label
    I18n.t("shared.statuses.#{status}", default: status.to_s)
  end

  # Delegate to course for convenience
  delegate :name, :name_ja, :localized_name, :secondary_name, :credits, :field, to: :course, allow_nil: true
end
