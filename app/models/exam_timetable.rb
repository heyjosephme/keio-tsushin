# frozen_string_literal: true

# ExamTimetable maps exam groups (A-F) to day/time slots based on season type.
# Data is loaded from config/exam_timetable.yml (not database).
class ExamTimetable
  GROUPS = %w[A B C D E F].freeze
  SEASON_TYPES = %w[apr_jul oct_jan].freeze

  Slot = Data.define(:group, :day, :time, :day_label)

  class << self
    def config
      @config ||= YAML.load_file(Rails.root.join("config/exam_timetable.yml"))
    end

    # Returns the Slot for a given group in a given season
    def slot_for(group:, season:)
      return nil if group.blank?

      season_type = season_type_for(season)
      slot_index = config.dig("schedule", season_type, group)
      return nil unless slot_index

      slot_data = config["time_slots"][slot_index]
      Slot.new(
        group: group,
        day: slot_data["day"],
        time: slot_data["time"],
        day_label: slot_data["day"] == "saturday" ? "土曜日" : "日曜日"
      )
    end

    # Returns all slots for a season, sorted by day/time
    def slots_for_season(season)
      season_type = season_type_for(season)
      schedule = config.dig("schedule", season_type) || {}

      schedule.map do |group, slot_index|
        slot_data = config["time_slots"][slot_index]
        Slot.new(
          group: group,
          day: slot_data["day"],
          time: slot_data["time"],
          day_label: slot_data["day"] == "saturday" ? "土曜日" : "日曜日"
        )
      end.sort_by { |s| config["time_slots"].index { |ts| ts["day"] == s.day && ts["time"] == s.time } }
    end

    # Build exam schedule for a list of enrollments in a season
    # Returns array of { slot:, courses: [] } sorted by time
    def schedule_for(enrollments:, season:)
      grouped = enrollments.group_by { |e| e.course&.exam_group }
      grouped.delete(nil) # skip courses without exam_group

      grouped.map do |group, group_enrollments|
        slot = slot_for(group: group, season: season)
        next unless slot

        { slot: slot, courses: group_enrollments.map(&:course).compact }
      end.compact.sort_by { |entry| [ entry[:slot].day == "saturday" ? 0 : 1, entry[:slot].time ] }
    end

    # Detect conflicts: multiple courses in the same exam group
    def conflicts_for(enrollments:)
      grouped = enrollments.group_by { |e| e.course&.exam_group }
      grouped.delete(nil)

      grouped.select { |_group, group_enrollments| group_enrollments.size > 1 }
    end

    # Determine season type from a Season object
    def season_type_for(season)
      month = season.exam_start.month
      %w[4 7].include?(month.to_s) ? "apr_jul" : "oct_jan"
    end
  end
end
