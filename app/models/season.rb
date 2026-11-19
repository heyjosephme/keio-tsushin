# frozen_string_literal: true

# Season represents three months of study ending with an exam weekend. Its key is
# the month it starts ("202610"); the exams come at the start of the next quarter.
# Data is loaded from config/seasons.yml (not database).
class Season
  attr_reader :key, :report_deadline,
              :application_deadline, :exam_start, :exam_end

  # A dated entry on the deadlines calendar. Every event comes from config/seasons.yml
  # and is the same for all students.
  Event = Data.define(:season, :type, :date) do
    def title
      I18n.t("season_events.#{type}.title")
    end

    def short_title
      I18n.t("season_events.#{type}.short")
    end

    def days_left(today = Date.today)
      (date - today).to_i
    end

    def estimated?
      season.estimated?
    end
  end

  def initialize(key:, data:)
    @key = key.to_s  # YAML parses 2026_01 as integer, ensure string
    @report_deadline = Date.parse(data["report_deadline"])
    @application_deadline = Date.parse(data["application_deadline"])
    @exam_start = Date.parse(data["exam_start"])
    @exam_end = Date.parse(data["exam_end"])
    @estimated = data["estimated"] == true
  end

  # True while the official dates aren't announced and seasons.yml holds a guess
  def estimated?
    @estimated
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

    # Seasons whose exams aren't over yet. A season stays here after its report
    # deadline, because courses in it still have an application and an exam ahead.
    def upcoming(limit = 4)
      all.reject(&:past?).first(limit)
    end

    # Seasons whose exams are over, most recent first
    def past
      all.select(&:past?).reverse
    end

    def for_select
      all.map { |s| [ s.label, s.key ] }
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

  # The first day of the season, from its key ("202610" → October 1, 2026)
  def start_date
    Date.strptime(key, "%Y%m")
  end

  # The season's start month: "October 2026" / "2026年10月", in the current locale
  def name
    I18n.l(start_date, format: :month_year)
  end

  # "Oct '26" / "2026年10月"
  def short_name
    I18n.l(start_date, format: :season_short)
  end

  # The month of the exams that end the season: "January 2027" / "2027年1月"
  def exam_name
    I18n.l(exam_start, format: :month_year)
  end

  # For season pickers, where the exam month matters: "Oct '26 (Jan '27 exams)"
  def label
    I18n.t("shared.season_label", season: short_name, exams: I18n.l(exam_start, format: :season_short))
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
