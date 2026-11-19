require "test_helper"

class SeasonTest < ActiveSupport::TestCase
  test "a season has a report deadline, an application deadline, and an event per exam day" do
    season = Season.find("202610")

    assert_equal [
      [ "report", Date.new(2026, 11, 18) ],
      [ "application", Date.new(2026, 11, 25) ],
      [ "exam", Date.new(2027, 1, 23) ],
      [ "exam", Date.new(2027, 1, 24) ]
    ], season.events.map { |event| [ event.type, event.date ] }
  end

  test "events_in returns only events inside the range, in date order" do
    events = Season.events_in(Date.new(2027, 2, 1)..Date.new(2027, 4, 30))

    assert_equal %w[report application exam exam], events.map(&:type)
    assert events.all? { |event| event.season.key == "202701" }
  end

  test "next_event finds the first event of a type on or after the given day" do
    assert_equal Date.new(2026, 11, 18), Season.next_event("report", from: Date.new(2026, 11, 1)).date
    assert_equal Date.new(2026, 11, 18), Season.next_event("report", from: Date.new(2026, 11, 18)).date
    assert_equal Date.new(2027, 3, 10), Season.next_event("application", from: Date.new(2026, 11, 26)).date
    assert_nil Season.next_event("report", from: Date.new(2030, 1, 1))
  end

  test "names follow the current locale" do
    season = Season.find("202610")

    # Named after the month the season starts; the exams are in January 2027
    assert_equal [ "October 2026", "Oct '26" ], [ season.name, season.short_name ]
    assert_equal "January 2027", season.exam_name
    assert_equal "Oct '26 (Jan '27 exams)", season.label
    I18n.with_locale(:ja) do
      assert_equal "2026年10月", season.name
      assert_equal "2027年1月", season.exam_name
      assert_equal "2026年10月期（2027年1月試験）", season.label
      assert_equal "レポート提出締切", season.events.first.title
    end
  end

  test "days_left counts from the given day" do
    event = Season.next_event("report", from: Date.new(2026, 11, 9))
    assert_equal 9, event.days_left(Date.new(2026, 11, 9))
  end

  test "a season flagged estimated marks its events as estimated" do
    assert_not Season.find("202610").estimated?
    assert Season.find("202701").estimated?
    assert Season.find("202701").events.all?(&:estimated?)
  end

  test "a season stays upcoming until its exams are over" do
    travel_to Date.new(2026, 11, 19) do # after the January 2027 report deadline
      assert_equal %w[202610 202701], Season.upcoming.map(&:key)
      assert_equal "202607", Season.past.first.key
    end

    travel_to Date.new(2027, 1, 25) do # the day after the January exams
      assert_equal %w[202701], Season.upcoming.map(&:key)
      assert_equal "202610", Season.past.first.key
    end
  end

  test "every season is keyed by the month it starts, three months before its exams" do
    Season.all.each do |season|
      assert_equal season.start_date >> 3, season.exam_start.beginning_of_month, "season #{season.key}"
    end
  end
end
