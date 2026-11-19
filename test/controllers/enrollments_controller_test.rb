require "test_helper"

class EnrollmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "should get index" do
    get enrollments_url
    assert_response :success
  end

  test "should get new" do
    get new_enrollment_url
    assert_response :success
  end

  test "should show enrollment" do
    get enrollment_url(enrollments(:one))
    assert_response :success
  end

  test "should create enrollment" do
    assert_difference("Enrollment.count") do
      post enrollments_url, params: { enrollment: {
        course_key: "eng101",
        season_key: "202604",
        status: "planned"
      } }
    end

    assert_redirected_to enrollments_url
  end

  test "should update enrollment" do
    enrollment = enrollments(:one)
    patch enrollment_url(enrollment), params: { enrollment: { season_key: "202607" } }
    assert_redirected_to enrollment_url(enrollment)
    assert_equal "202607", enrollment.reload.season_key
  end

  test "should destroy enrollment" do
    enrollment = enrollments(:one)
    assert_difference("Enrollment.count", -1) do
      delete enrollment_url(enrollment)
    end

    assert_redirected_to enrollments_url
  end

  test "index lists unscheduled required courses for the user's major as undecided" do
    @user.update!(major: "economics")

    get enrollments_url

    assert_response :success
    assert_select "h2", text: "Timing undecided"
    assert_select "form[action='#{enrollments_path}'] input[name='enrollment[course_key]'][value='stat101']"
  end

  test "index drops a required course from undecided once it has a season" do
    @user.update!(major: "economics")
    @user.enrollments.create!(course_key: "stat101", season_key: "202604", status: "planned")

    get enrollments_url

    assert_select "input[name='enrollment[course_key]'][value='stat101']", count: 0
    assert_select "input[name='enrollment[course_key]'][value='econ201']"
  end

  test "index has no undecided section once every required course has a season" do
    @user.update!(major: "economics")
    Course.required_for_major("economics").each do |course|
      @user.enrollments.create!(course_key: course.key, season_key: "202604", status: "planned")
    end

    get enrollments_url

    assert_select "h2", text: "Timing undecided", count: 0
  end

  test "index has no undecided section for a major without required courses" do
    @user.update!(major: "law")

    get enrollments_url

    assert_select "h2", text: "Timing undecided", count: 0
  end

  test "dashboard shows progress for each part of the graduation requirement" do
    @user.enrollments.create!(course_key: "econ204", season_key: "202701", status: "completed")

    get dashboard_enrollments_url

    assert_response :success
    assert_select "h2", "Graduation Requirements"
    assert_select "h3", "General Education"
    assert_select "p", "0 / 48 credits"
    assert_select "h3", "Specialized Education"
    assert_select "p", "4 / 68 credits"
    assert_select "h3", "Graduation Thesis"
    assert_select "p", "0 / 8 credits"
    assert_select "p", "120 credits remaining"
  end
end
