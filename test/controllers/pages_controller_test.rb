require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get home" do
    get root_url
    assert_response :success
  end

  test "visitors see the landing page" do
    get root_url
    assert_select "a", "Sign in"
    assert_select "h2", text: "Next steps", count: 0
  end

  test "signed-in users see their next steps instead of the landing page" do
    travel_to Date.new(2026, 11, 1) do
      user = users(:two)
      report = user.enrollments.create!(course_key: "phil101", season_key: "202701", status: "planned")
      user.enrollments.create!(course_key: "eng101", season_key: "202701", status: "completed")
      user.enrollments.create!(course_key: "logic101", season_key: "202701", status: "planned")
      sign_in_as(user)

      get root_url
      assert_response :success
      assert_select "h2", "Next steps"
      # Both planned courses share one deadline heading
      assert_select "p", text: /Submit the report by Wed, Nov 18, 2026 · 17 days left/, count: 1
      assert_select "button", text: "Mark report submitted", count: 2
      assert_select "form[action=?] button", enrollment_path(report), text: "Mark report submitted"
      assert_select "p", "2 of 124 credits completed"

      patch enrollment_url(report), params: { enrollment: { status: "report_submitted" } }, headers: { "Referer" => root_url }
      follow_redirect!
      assert_select "p", /Apply for the exam by Wed, Nov 25, 2026/
    end
  end

  test "a signed-in user without courses is pointed to the catalog" do
    sign_in_as(users(:two))

    get root_url
    assert_select "h2", "Start your plan"
    assert_select "a[href=?]", catalog_path, text: "Browse catalog"
    assert_select "a[href=?]", edit_profile_path, text: "Set up profile"
  end

  test "should get documents" do
    get documents_url
    assert_response :success
  end
end
