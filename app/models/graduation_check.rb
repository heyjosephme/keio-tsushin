# frozen_string_literal: true

# Checks a student's courses against the graduation requirements of the regular
# course (普通課程). Only the economics major's rules are implemented.
#
#   check = GraduationCheck.new(user: Current.user, enrollments: Current.user.enrollments)
#   check.sections   # => general, specialized, thesis and schooling, each a Requirement tree
#   check.remaining  # => credits still missing across the three credit areas
#
# Every Requirement carries two numbers: `completed` counts only completed courses,
# `planned` counts every course in the plan, so the dashboard can show both where the
# student stands and whether the current plan would be enough.
#
# Credits are "counted" credits: the rules cap how much schooling and how many
# elective-language credits may count, so a course's credits can exceed what it adds here.
#
# Not checked: the graduation exam (卒業試験), health and physical education (no such
# courses in the catalog), and the exact make-up of the 8 required language credits
# (study guide pp. 30-33), which is simplified to "8 credits in one language".
class GraduationCheck
  MAJOR = "economics"
  TOTAL_CREDITS = 124

  THREE_FIELDS = %w[humanities social natural].freeze
  REQUIRED_LANGUAGES = %w[english german french].freeze

  GENERAL_CREDITS = 48
  THREE_FIELDS_CREDITS = 32
  FIELD_CREDITS = 6
  FIELD_COURSES = 2
  THREE_FIELDS_DISTANCE_CREDITS = 24
  THREE_FIELDS_SCHOOLING_CAP = 12
  REQUIRED_LANGUAGE_CREDITS = 8
  ELECTIVE_LANGUAGE_CAP = 2       # per language
  ELECTIVE_LANGUAGES = 2          # so at most 4 credits in total

  SPECIALIZED_CREDITS = 68
  ELECTIVE_CREDITS = 51
  ELECTIVE_DISTANCE_CREDITS = 23
  ELECTIVE_SCHOOLING_CAP = 28
  SPECIALIZED_DISTANCE_CREDITS = 40

  THESIS_CREDITS = 8

  SCHOOLING_CREDITS = 30
  SCHOOLING_MEDIA_CAP = 10

  # unit is :credits, :courses or :done (a yes/no item, required is 1)
  Requirement = Data.define(:key, :unit, :completed, :planned, :required, :children) do
    def met?
      completed >= required
    end

    # Not met yet, but the courses in the plan would be enough
    def on_track?
      !met? && planned >= required
    end

    # This requirement and everything under it
    def all_met?
      met? && children.all?(&:all_met?)
    end

    def all_on_track?
      planned >= required && children.all?(&:all_on_track?)
    end

    def label
      I18n.t("graduation.requirements.#{key}")
    end
  end

  def initialize(user:, enrollments:)
    @user = user
    enrollments = enrollments.to_a
    @done = tally(enrollments.select { |e| e.status == "completed" })
    @plan = tally(enrollments)
  end

  def sections
    [ general, specialized, thesis, schooling ]
  end

  def total
    requirement(:total, TOTAL_CREDITS)
  end

  def met?
    sections.all?(&:all_met?)
  end

  # Credits still missing. Surplus in one area doesn't make up for another.
  def remaining
    [ general, specialized, thesis ].sum { |area| [ area.required - area.completed, 0 ].max }
  end

  # The language the 8 required credits are being earned in, if any
  def required_language
    @plan[:language]
  end

  def general
    requirement(:general, GENERAL_CREDITS, children: [
      requirement(:three_fields, THREE_FIELDS_CREDITS, children: [
        *THREE_FIELDS.flat_map do |field|
          [
            requirement(:"#{field}_credits", FIELD_CREDITS),
            requirement(:"#{field}_courses", FIELD_COURSES, unit: :courses)
          ]
        end,
        requirement(:three_fields_distance, THREE_FIELDS_DISTANCE_CREDITS),
        requirement(:statistics, 1, unit: :done)
      ]),
      requirement(:required_language, REQUIRED_LANGUAGE_CREDITS)
    ])
  end

  def specialized
    requirement(:specialized, SPECIALIZED_CREDITS, children: [
      requirement(:required_courses, required_specialized.sum(&:credits)),
      requirement(:electives, ELECTIVE_CREDITS, children: [
        requirement(:electives_distance, ELECTIVE_DISTANCE_CREDITS)
      ]),
      requirement(:specialized_distance, SPECIALIZED_DISTANCE_CREDITS)
    ])
  end

  def thesis
    requirement(:thesis, THESIS_CREDITS)
  end

  def schooling
    requirement(:schooling, SCHOOLING_CREDITS)
  end

  private

  def requirement(key, required, unit: :credits, children: [])
    Requirement.new(key: key, unit: unit, completed: @done.fetch(key), planned: @plan.fetch(key), required: required, children: children)
  end

  # The compulsory specialized courses (17 credits, distance only)
  def required_specialized
    @required_specialized ||= Course.required_for_major(MAJOR).select { |course| course.field == MAJOR }
  end

  # The compulsory general courses: Statistics, by distance learning
  def required_general
    @required_general ||= Course.required_for_major(MAJOR).select { |course| THREE_FIELDS.include?(course.field) }
  end

  def tally(enrollments)
    courses = enrollments.filter_map(&:course)
    counts = {}

    # General education: the three fields
    three = courses.select { |course| THREE_FIELDS.include?(course.field) }
    THREE_FIELDS.each do |field|
      in_field = three.select { |course| course.field == field }
      counts[:"#{field}_credits"] = credits(in_field)
      counts[:"#{field}_courses"] = in_field.size
    end
    counts[:three_fields_distance] = credits(three.select(&:by_distance?))
    counts[:three_fields] = counts[:three_fields_distance] + [ credits(three.select(&:schooling?)), THREE_FIELDS_SCHOOLING_CAP ].min
    counts[:statistics] = required_general.any? && required_general.all? { |course| course.by_distance? && courses.include?(course) } ? 1 : 0

    # General education: languages
    by_language = courses.select { |course| course.field == "foreign_language" }.group_by(&:language).transform_values { |list| credits(list) }
    language = REQUIRED_LANGUAGES.select { |name| by_language[name].to_i > 0 }.max_by { |name| by_language[name] }
    electives = by_language.except(language).values.map { |sum| [ sum, ELECTIVE_LANGUAGE_CAP ].min }.max(ELECTIVE_LANGUAGES).sum
    counts[:language] = language
    counts[:required_language] = [ by_language[language].to_i, REQUIRED_LANGUAGE_CREDITS ].min
    counts[:general] = counts[:three_fields] + counts[:required_language] + electives

    # Specialized education
    special = courses.select { |course| course.field == MAJOR }
    required, elective = special.partition { |course| required_specialized.include?(course) }
    counts[:required_courses] = credits(required.select(&:by_distance?))
    counts[:electives_distance] = credits(elective.select(&:by_distance?))
    counts[:electives] = counts[:electives_distance] + [ credits(elective.select(&:schooling?)), ELECTIVE_SCHOOLING_CAP ].min
    counts[:specialized_distance] = counts[:required_courses] + counts[:electives_distance]
    counts[:specialized] = counts[:required_courses] + counts[:electives]

    # Thesis: recorded on the profile, not as a course
    counts[:thesis] = @user&.thesis_completed? ? THESIS_CREDITS : 0

    # Schooling across the whole course; media courses count for at most 10 of the 30
    counts[:schooling] = credits(courses.select(&:on_campus?)) + [ credits(courses.select(&:media?)), SCHOOLING_MEDIA_CAP ].min

    counts[:total] = counts[:general] + counts[:specialized] + counts[:thesis]
    counts
  end

  def credits(courses)
    courses.sum { |course| course.credits.to_i }
  end
end
