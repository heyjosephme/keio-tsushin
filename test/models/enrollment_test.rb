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

  test "graduation areas add up to the credits needed to graduate" do
    assert_equal Enrollment::CREDITS_REQUIRED, Enrollment::GRADUATION_AREAS.values.sum { |area| area[:required] }
    assert_equal Course::FIELDS.sort, Enrollment::GRADUATION_AREAS.values.flat_map { |area| area[:fields] }.sort
  end

  test "credits_by_area groups credits into general, specialized and thesis" do
    user = users(:two)
    user.enrollments.create!(course_key: "stat101", season_key: "202610", status: "completed")  # natural, 4
    user.enrollments.create!(course_key: "eng101", season_key: "202610", status: "planned")     # foreign language, 2
    user.enrollments.create!(course_key: "econ204", season_key: "202610", status: "completed")  # economics, 4
    user.enrollments.create!(course_key: "econ206", season_key: "202610", status: "exam_applied") # economics, 3

    areas = user.enrollments.credits_by_area

    assert_equal({ completed: 4, in_progress: 0, planned: 2, total: 6, required: 48 }, areas["general"])
    assert_equal({ completed: 4, in_progress: 3, planned: 0, total: 7, required: 68 }, areas["specialized"])
    assert_equal({ completed: 0, in_progress: 0, planned: 0, total: 0, required: 8 }, areas["thesis"])
  end
end
