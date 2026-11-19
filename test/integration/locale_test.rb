require "test_helper"

class LocaleTest < ActionDispatch::IntegrationTest
  PUBLIC_PAGES = %w[/ /about /documents /session/new /passwords/new].freeze
  SIGNED_IN_PAGES = %w[/ /courses /courses/new /courses/dashboard /catalog /catalog/phil101 /deadlines /profile /profile/edit].freeze

  # Missing translations raise in the test environment, so rendering every page in
  # both languages catches keys that exist in only one locale file.
  %w[en ja].each do |locale|
    test "every page renders in #{locale}" do
      PUBLIC_PAGES.each do |page|
        get page, params: { locale: locale }
        assert_response :success, "#{page} (#{locale})"
        assert_select "html[lang=?]", locale
      end

      sign_in_as(users(:one))
      (SIGNED_IN_PAGES + [ enrollment_path(enrollments(:one)), "/deadlines?year=2027&month=1" ]).each do |page|
        get page, params: { locale: locale }
        assert_response :success, "#{page} (#{locale})"
      end
    end
  end

  test "defaults to English" do
    get new_session_url
    assert_select "h1", "Sign in"
  end

  test "uses the browser's language when it is available" do
    get new_session_url, headers: { "Accept-Language" => "ja-JP,ja;q=0.9,en;q=0.8" }
    assert_select "h1", "ログイン"

    get new_session_url, headers: { "Accept-Language" => "fr-FR,fr;q=0.9" }
    assert_select "h1", "Sign in"
  end

  test "the locale param wins and is remembered" do
    get new_session_url, params: { locale: "ja" }, headers: { "Accept-Language" => "en-US" }
    assert_select "h1", "ログイン"

    get new_session_url, headers: { "Accept-Language" => "en-US" }
    assert_select "h1", "ログイン"

    get new_session_url, params: { locale: "en" }
    assert_select "h1", "Sign in"
  end

  test "ignores unknown locales" do
    get new_session_url, params: { locale: "xx" }
    assert_response :success
    assert_select "h1", "Sign in"
  end

  test "the switcher links to the same page in the other language" do
    sign_in_as(users(:one))

    get deadlines_url(year: 2027, month: 1)
    assert_select "a[lang=ja][href=?]", "/deadlines?locale=ja&month=1&year=2027", text: "日本語"

    get deadlines_url(year: 2027, month: 1, locale: "ja")
    assert_select "a[lang=en][href=?]", "/deadlines?locale=en&month=1&year=2027", text: "English"
    assert_select "h2", "2027年1月"
  end

  test "courses, seasons and flash messages are localized" do
    # Before the January 2027 report deadline, so that season is still on the board
    travel_to Date.new(2026, 11, 1) do
      sign_in_as(users(:one))

      get catalog_course_url("phil101", locale: "ja")
      assert_select "h1", "哲学"

      get catalog_course_url("no_such_course")
      follow_redirect!
      assert_select "p", "科目が見つかりません。"

      get enrollments_url
      assert_select "h2", "2026年10月"
      assert_select "h2", /2027年1月\s*予定/
    end
  end

  test "validation errors are localized" do
    sign_in_as(users(:one))

    post enrollments_url, params: { locale: "ja", enrollment: { course_key: "phil101", season_key: "202610" } }
    assert_response :unprocessable_entity
    assert_select "p", "科目はすでに履修計画に入っています"
  end
end
