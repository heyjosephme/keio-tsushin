require "test_helper"

class CoursesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
  end

  test "should get index" do
    get catalog_url
    assert_response :success
  end

  test "should show course" do
    get catalog_course_url("phil101")
    assert_response :success
  end

  test "unknown course redirects to the catalog with an alert" do
    get catalog_course_url("no_such_course")
    assert_redirected_to catalog_url

    follow_redirect!
    assert_select "p", "Course not found."
  end
end
