require "test_helper"

class DeadlinesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
  end

  test "shows the current month" do
    get deadlines_url
    assert_response :success
    assert_select "p", /Next report deadline/
  end

  test "shows report, application and both exam days from seasons.yml" do
    get deadlines_url(year: 2027, month: 1)
    assert_response :success

    assert_select "h2", "January 2027"
    assert_select "p", text: "Report submission deadline", count: 1
    assert_select "p", text: "Exam application deadline", count: 1
    assert_select "p", text: "Exam day", count: 2
  end

  test "falls back to the current month for an invalid date" do
    get deadlines_url(year: 2027, month: 13)
    assert_response :success
    assert_select "h2", Date.today.strftime("%B %Y")
  end

  test "deadlines can't be created or deleted" do
    assert_raises(ActionController::RoutingError) { Rails.application.routes.recognize_path("/deadlines", method: :post) }
    assert_raises(ActionController::RoutingError) { Rails.application.routes.recognize_path("/deadlines/1", method: :delete) }
  end
end
