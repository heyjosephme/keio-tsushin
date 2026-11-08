require "test_helper"

class CourseTest < ActiveSupport::TestCase
  test "every field's report PDF key matches a slot on the documents page" do
    document_keys = Views::Pages::Documents::REPORT_CATEGORIES.map { |category| category[:key] }

    Course::FIELDS.each do |field|
      course = Course.new(key: "test", data: { "field" => field })
      assert_includes document_keys, course.report_pdf, "no documents-page slot for #{field} reports"
    end
  end
end
