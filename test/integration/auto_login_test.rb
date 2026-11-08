require "test_helper"

class AutoLoginTest < ActionDispatch::IntegrationTest
  test "AUTO_LOGIN_EMAIL never signs anyone in outside development" do
    previous = ENV["AUTO_LOGIN_EMAIL"]
    ENV["AUTO_LOGIN_EMAIL"] = users(:one).email_address

    get enrollments_url
    assert_redirected_to new_session_url
  ensure
    ENV["AUTO_LOGIN_EMAIL"] = previous
  end
end
