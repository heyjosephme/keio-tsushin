# frozen_string_literal: true

# Season represents a Keio Tsushin exam period.
# Data is loaded from config/seasons.yml (not database).
class Season
  attr_reader :key, :name, :short_name, :report_deadline,
              :application_deadline, :exam_start, :exam_end

  def initialize(key:, data:)
    @key = key
    @name = data["name"]
    @short_name = data["short_name"]
    @report_deadline = Date.parse(data["report_deadline"])
    @application_deadline = Date.parse(data["application_deadline"])
    @exam_start = Date.parse(data["exam_start"])
    @exam_end = Date.parse(data["exam_end"])
  end

  class << self
    def all
      @all ||= load_seasons
    end

    def find(key)
      all.find { |s| s.key == key }
    end

    def current
      today = Date.today
      all.find { |s| s.exam_end >= today } || all.last
    end

    def upcoming(limit = 4)
      today = Date.today
      all.select { |s| s.report_deadline >= today }.first(limit)
    end

    def for_select
      all.map { |s| [ s.name, s.key ] }
    end

    private

    def load_seasons
      config = YAML.load_file(Rails.root.join("config/seasons.yml"))
      config["seasons"].map do |key, data|
        new(key: key, data: data)
      end.sort_by(&:exam_start)
    end
  end

  def past?
    exam_end < Date.today
  end

  def current?
    Date.today.between?(report_deadline - 30, exam_end)
  end

  def days_until_report_deadline
    (report_deadline - Date.today).to_i
  end

  def days_until_application_deadline
    (application_deadline - Date.today).to_i
  end
end
