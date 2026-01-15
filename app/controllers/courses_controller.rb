class CoursesController < ApplicationController
  def index
    @seasons = Season.upcoming(4)
    @courses_by_season = Course.all.group_by(&:season_key)

    render Views::Courses::Index.new(
      seasons: @seasons,
      courses_by_season: @courses_by_season
    )
  end

  def new
    @course = Course.new(season_key: params[:season_key])
    @seasons = Season.upcoming(4)

    render Views::Courses::New.new(course: @course, seasons: @seasons)
  end

  def create
    @course = Course.new(course_params)
    @course.status ||= "planned"

    if @course.save
      redirect_to courses_path, notice: "Course added!"
    else
      @seasons = Season.upcoming(4)
      render Views::Courses::New.new(course: @course, seasons: @seasons), status: :unprocessable_entity
    end
  end

  def update
    @course = Course.find(params[:id])

    if @course.update(course_params)
      redirect_to courses_path, notice: "Course updated!"
    else
      redirect_to courses_path, alert: "Failed to update course."
    end
  end

  def destroy
    @course = Course.find(params[:id])
    @course.destroy
    redirect_to courses_path, notice: "Course removed."
  end

  private

  def course_params
    params.require(:course).permit(:name, :season_key, :status, :credits)
  end
end
