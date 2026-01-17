require "test_helper"

class DeadlinesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "should get index" do
    get deadlines_url
    assert_response :success
  end

  test "should get new" do
    get new_deadline_url
    assert_response :success
  end

  test "should create deadline" do
    assert_difference("Deadline.count") do
      post deadlines_url, params: { deadline: {
        course_name: "Test Course",
        deadline_date: Date.today + 7.days,
        deadline_type: "report",
        description: "Test description"
      } }
    end

    assert_redirected_to deadlines_url
  end

  test "should destroy deadline" do
    deadline = deadlines(:one)
    assert_difference("Deadline.count", -1) do
      delete deadline_url(deadline)
    end

    assert_redirected_to deadlines_url
  end
end
