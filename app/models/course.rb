# frozen_string_literal: true

# Course represents a Keio Tsushin course from the catalog.
# Data is loaded from config/courses.yml (not database).
class Course
  attr_reader :key, :name, :name_ja, :credits, :category, :type

  CATEGORIES = %w[required elective foreign_language physical_education].freeze
  TYPES = %w[distance on_campus both].freeze

  def initialize(key:, data:)
    @key = key
    @name = data["name"]
    @name_ja = data["name_ja"]
    @credits = data["credits"]
    @category = data["category"]
    @type = data["type"]
  end

  class << self
    def all
      @all ||= load_courses
    end

    def find(key)
      all.find { |c| c.key == key }
    end

    def by_category(category)
      all.select { |c| c.category == category }
    end

    def required
      by_category("required")
    end

    def elective
      by_category("elective")
    end

    def foreign_language
      by_category("foreign_language")
    end

    def for_select
      all.map { |c| ["#{c.name} (#{c.credits} credits)", c.key] }
    end

    def grouped_for_select
      all.group_by(&:category).transform_values do |courses|
        courses.map { |c| ["#{c.name} (#{c.credits}単位)", c.key] }
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

  def required?
    category == "required"
  end

  def distance?
    type == "distance"
  end

  def display_name
    "#{name} (#{name_ja})"
  end

  def category_label
    {
      "required" => "必修",
      "elective" => "選択",
      "foreign_language" => "外国語",
      "physical_education" => "体育"
    }[category] || category
  end
end
