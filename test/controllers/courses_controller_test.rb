require "test_helper"

class CoursesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get courses_url
    assert_response :success
  end

  test "should get new" do
    get new_course_url
    assert_response :success
  end

  test "should create course" do
    assert_difference("Course.count") do
      post courses_url, params: { course: {
        name: "Test Course",
        season_key: "2026_04",
        status: "planned",
        credits: 2
      } }
    end

    assert_redirected_to courses_url
  end

  test "should update course" do
    course = courses(:one)
    patch course_url(course), params: { course: { season_key: "2026_07" } }
    assert_redirected_to courses_url
  end

  test "should destroy course" do
    course = courses(:one)
    assert_difference("Course.count", -1) do
      delete course_url(course)
    end

    assert_redirected_to courses_url
  end
end
