require "test_helper"

class CourseTest < ActiveSupport::TestCase
  test "every field's report PDF key matches a slot on the documents page" do
    document_keys = Views::Pages::Documents::REPORT_CATEGORIES.map { |category| category[:key] }

    Course::FIELDS.each do |field|
      course = Course.new(key: "test", data: { "field" => field })
      assert_includes document_keys, course.report_pdf, "no documents-page slot for #{field} reports"
    end
  end

  test "required_for? is true only for the majors listed in required_for" do
    course = Course.new(key: "test", data: { "required_for" => [ "economics" ] })

    assert course.required_for?("economics")
    assert_not course.required_for?("law")
    assert_not course.required_for?(nil)
  end

  test "courses are not required for any major by default" do
    assert_not Course.new(key: "test", data: {}).required_for?("economics")
  end

  test "statistics is a natural science course required for economics majors" do
    statistics = Course.find("stat101")

    assert_equal "natural", statistics.field
    assert_equal 4, statistics.credits
    assert statistics.required_for?("economics")
  end
end
