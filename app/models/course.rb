# frozen_string_literal: true

# Course represents a Keio Tsushin course from the catalog.
# Data is loaded from config/courses.yml (not database).
class Course
  attr_reader :key, :name, :name_ja, :credits, :field, :type, :majors, :references

  FIELDS = %w[humanities social natural foreign_language economics].freeze
  TYPES = %w[distance on_campus both].freeze
  MAJORS = %w[economics law literature].freeze

  def initialize(key:, data:)
    @key = key
    @name = data["name"]
    @name_ja = data["name_ja"]
    @credits = data["credits"]
    @field = data["field"]
    @type = data["type"]
    @majors = data["majors"] || [ "all" ]
    @references = data["references"] || {}
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

  def field_label
    {
      "humanities" => "人文科学",
      "social" => "社会科学",
      "natural" => "自然科学",
      "foreign_language" => "外国語",
      "economics" => "経済学"
    }[field] || field
  end

  def report_pdf
    "reports_#{field}" if field
  end

  def available_for_major?(major)
    majors.include?("all") || majors.include?(major)
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
