require "test_helper"

class SeasonTest < ActiveSupport::TestCase
  test "a season has a report deadline, an application deadline, and an event per exam day" do
    season = Season.find("202701")

    assert_equal [
      [ "report", Date.new(2027, 1, 10) ],
      [ "application", Date.new(2027, 1, 15) ],
      [ "exam", Date.new(2027, 1, 23) ],
      [ "exam", Date.new(2027, 1, 24) ]
    ], season.events.map { |event| [ event.type, event.date ] }
  end

  test "events_in returns only events inside the range, in date order" do
    events = Season.events_in(Date.new(2027, 4, 1)..Date.new(2027, 4, 30))

    assert_equal %w[report application exam exam], events.map(&:type)
    assert events.all? { |event| event.season.key == "202704" }
  end

  test "next_event finds the first event of a type on or after the given day" do
    assert_equal Date.new(2027, 1, 10), Season.next_event("report", from: Date.new(2026, 11, 17)).date
    assert_equal Date.new(2027, 1, 10), Season.next_event("report", from: Date.new(2027, 1, 10)).date
    assert_equal Date.new(2027, 4, 15), Season.next_event("application", from: Date.new(2027, 1, 16)).date
    assert_nil Season.next_event("report", from: Date.new(2030, 1, 1))
  end

  test "days_left counts from the given day" do
    event = Season.next_event("report", from: Date.new(2027, 1, 1))
    assert_equal 9, event.days_left(Date.new(2027, 1, 1))
  end
end
