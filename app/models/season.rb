# frozen_string_literal: true

# Season represents a Keio Tsushin exam period.
# Data is loaded from config/seasons.yml (not database).
class Season
  attr_reader :key, :name, :short_name, :report_deadline,
              :application_deadline, :exam_start, :exam_end

  # A dated entry on the deadlines calendar. Every event comes from config/seasons.yml
  # and is the same for all students.
  Event = Data.define(:season, :type, :date) do
    def title
      { "report" => "Report submission deadline", "application" => "Exam application deadline", "exam" => "Exam day" }.fetch(type)
    end

    def short_title
      { "report" => "Report", "application" => "Apply", "exam" => "Exam" }.fetch(type)
    end

    def days_left(today = Date.today)
      (date - today).to_i
    end
  end

  def initialize(key:, data:)
    @key = key.to_s  # YAML parses 2026_01 as integer, ensure string
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

    # All events of all seasons, in date order
    def events
      all.flat_map(&:events).sort_by(&:date)
    end

    def events_in(date_range)
      events.select { |event| date_range.cover?(event.date) }
    end

    # The next event of a type ("report", "application" or "exam") on or after the given day
    def next_event(type, from: Date.today)
      events.find { |event| event.type == type && event.date >= from }
    end

    private

    def load_seasons
      config = YAML.load_file(Rails.root.join("config/seasons.yml"))
      config["seasons"].map do |key, data|
        new(key: key, data: data)
      end.sort_by(&:exam_start)
    end
  end

  # Report deadline, application deadline, and one event per exam day
  def events
    [
      Event.new(season: self, type: "report", date: report_deadline),
      Event.new(season: self, type: "application", date: application_deadline),
      *(exam_start..exam_end).map { |day| Event.new(season: self, type: "exam", date: day) }
    ]
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

  # April/July exams follow A→F order, October/January follow F→A order
  def season_type
    %w[4 7].include?(exam_start.month.to_s) ? "apr_jul" : "oct_jan"
  end
end
