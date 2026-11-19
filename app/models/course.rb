# frozen_string_literal: true

# Course represents a Keio Tsushin course from the catalog.
# Data is loaded from config/courses.yml (not database).
class Course
  attr_reader :key, :name, :name_ja, :credits, :field, :type, :majors, :references, :exam_group, :required_for

  FIELDS = %w[humanities social natural foreign_language economics].freeze
  TYPES = %w[distance on_campus both].freeze
  MAJORS = %w[economics law literature].freeze

  # Report-topic PDF slots on the Documents page (Views::Pages::Documents). Not derived
  # from the field name: foreign-language PDFs are stored under "reports_foreign_lang".
  REPORT_PDF_KEYS = {
    "humanities" => "reports_humanities",
    "social" => "reports_social",
    "natural" => "reports_natural",
    "foreign_language" => "reports_foreign_lang",
    "economics" => "reports_economics"
  }.freeze

  def initialize(key:, data:)
    @key = key
    @name = data["name"]
    @name_ja = data["name_ja"]
    @credits = data["credits"]
    @field = data["field"]
    @type = data["type"]
    @majors = data["majors"] || [ "all" ]
    @references = data["references"] || {}
    @exam_group = data["exam_group"]
    @required_for = data["required_for"] || []
  end

  class << self
    def all
      @all ||= load_courses
    end

    def find(key)
      all.find { |c| c.key == key }
    end

    def by_field(field)
      all.select { |c| c.field == field }
    end

    def for_major(major)
      return all if major.blank?

      all.select { |c| c.available_for_major?(major) }
    end

    # Courses that are compulsory (必修) for the given major
    def required_for_major(major)
      all.select { |c| c.required_for?(major) }
    end

    def for_select
      all.map { |c| [ "#{c.name} (#{c.credits} credits)", c.key ] }
    end

    def grouped_for_select
      all.group_by(&:field).transform_values do |courses|
        courses.map { |c| [ "#{c.name} (#{c.credits}単位)", c.key ] }
      end
    end

    def reload!
      @all = nil
      all
    end

    private

    def load_courses
      config = YAML.load_file(Rails.root.join("config/courses.yml"))
      config["courses"].map do |key, data|
        new(key: key, data: data)
      end.sort_by(&:name)
    end
  end

  def distance?
    type == "distance"
  end

  def display_name
    "#{name} (#{name_ja})"
  end

  # The course name in the current locale: name_ja in Japanese, name otherwise
  def localized_name
    I18n.locale == :ja && name_ja.present? ? name_ja : name
  end

  # The name in the other language, shown as a subtitle
  def secondary_name
    localized_name == name ? name_ja : name
  end

  def field_label
    I18n.t("shared.fields.#{field}", default: field.to_s)
  end

  def type_label
    I18n.t("shared.course_types.#{type}", default: type.to_s) if type
  end

  def major_labels
    majors.map { |major| I18n.t("shared.majors.#{major}", default: major.to_s) }
  end

  def report_pdf
    REPORT_PDF_KEYS[field]
  end

  def available_for_major?(major)
    majors.include?("all") || majors.include?(major)
  end

  # Whether the course is compulsory (必修) for students of the given major
  def required_for?(major)
    major.present? && required_for.include?(major)
  end

  def common?
    majors.include?("all")
  end

  def syllabus_page
    references["syllabus_page"]
  end

  def report_page
    references["report_page"]
  end

  def has_references?
    references.any?
  end
end
