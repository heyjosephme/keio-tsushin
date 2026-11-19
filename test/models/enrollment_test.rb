require "test_helper"

class EnrollmentTest < ActiveSupport::TestCase
  TODAY = Date.new(2026, 11, 1)

  def step(status, season_key: "202610", course_key: "phil101")
    Enrollment.new(course_key: course_key, season_key: season_key, status: status).next_step(TODAY)
  end

  test "next step follows the status" do
    assert_equal [ :submit_report, Date.new(2026, 11, 18), "report_submitted" ], step("planned").to_h.values_at(:action, :date, :next_status)
    assert_equal [ :apply_exam, Date.new(2026, 11, 25), "exam_applied" ], step("report_submitted").to_h.values_at(:action, :date, :next_status)
    assert_equal [ :take_exam, "completed" ], step("exam_applied").to_h.values_at(:action, :next_status)
    assert_nil step("completed")
  end

  test "the exam date is the day of the course's exam slot" do
    # phil101 is group E: Saturday in January (F→A order), Sunday in April (A→F order)
    assert_equal Date.new(2027, 1, 23), step("exam_applied").date
    assert_equal Date.new(2027, 4, 18), step("exam_applied", season_key: "202701").date
    # lit101 has no exam group
    assert_equal Date.new(2027, 1, 23), step("exam_applied", course_key: "lit101").date
  end

  test "missed deadlines and past exams" do
    assert_equal :reschedule, step("planned", season_key: "202607").action
    assert_equal :reschedule, step("report_submitted", season_key: "202607").action
    assert_equal :record_result, step("exam_applied", season_key: "202607").action
  end

  test "no next step for an unknown season" do
    assert_nil step("planned", season_key: "209901")
  end
end
