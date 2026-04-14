class CoursesController < ApplicationController
  def index
    @field = params[:field].presence
    @exclude_enrolled = params[:exclude_enrolled] == "1"

    @courses = scoped_courses
    @enrolled_keys = Current.user.enrollments.pluck(:course_key).to_set

    render Views::Catalog::Index.new(
      courses: @courses,
      field: @field,
      exclude_enrolled: @exclude_enrolled,
      enrolled_keys: @enrolled_keys
    )
  end

  def show
    @course = Course.find(params[:key])
    return redirect_to catalog_path, alert: "Course not found." unless @course

    @seasons = Season.upcoming(4)
    @existing_enrollment = Current.user.enrollments.find_by(course_key: @course.key)

    render Views::Catalog::Show.new(
      course: @course,
      seasons: @seasons,
      existing_enrollment: @existing_enrollment
    )
  end

  private

  def scoped_courses
    courses = Course.for_major(Current.user.major)
    courses = courses.select { |c| c.field == @field } if @field
    courses = courses.reject { |c| enrolled_keys.include?(c.key) } if @exclude_enrolled
    courses
  end

  def enrolled_keys
    @enrolled_keys ||= Current.user.enrollments.pluck(:course_key).to_set
  end
end
