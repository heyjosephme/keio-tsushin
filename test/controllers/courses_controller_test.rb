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

  test "the add-to-plan form on the course page adds the course" do
    get catalog_course_url("eng101")

    # Submit exactly the fields the rendered form contains
    fields = css_select("form[action='#{enrollments_path}'] input[name^='enrollment']").to_h { |input| [ input["name"], input["value"] ] }
    season_key = css_select("input[name='enrollment[season_key]']").first["value"]

    assert_difference("Enrollment.count") do
      post enrollments_url, params: Rack::Utils.parse_nested_query(fields.merge("enrollment[season_key]" => season_key).to_query)
    end
    assert_redirected_to enrollments_url
    assert_equal [ "eng101", season_key, "planned" ], Enrollment.last.values_at(:course_key, :season_key, :status)
  end

  test "unknown course redirects to the catalog with an alert" do
    get catalog_course_url("no_such_course")
    assert_redirected_to catalog_url

    follow_redirect!
    assert_select "p", "Course not found."
  end
end
