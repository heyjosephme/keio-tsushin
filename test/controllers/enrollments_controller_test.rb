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

  test "should create enrollment" do
    assert_difference("Enrollment.count") do
      post enrollments_url, params: { enrollment: {
        course_key: "phil101",
        season_key: "2026_04",
        status: "planned"
      } }
    end

    assert_redirected_to enrollments_url
  end

  test "should update enrollment" do
    enrollment = enrollments(:one)
    patch enrollment_url(enrollment), params: { enrollment: { season_key: "2026_07" } }
    assert_redirected_to enrollments_url
  end

  test "should destroy enrollment" do
    enrollment = enrollments(:one)
    assert_difference("Enrollment.count", -1) do
      delete enrollment_url(enrollment)
    end

    assert_redirected_to enrollments_url
  end
end
