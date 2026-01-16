class EnrollmentsController < ApplicationController
  def index
    @seasons = Season.upcoming(4)
    @enrollments_by_season = Enrollment.all.group_by(&:season_key)
    @courses = Course.all

    render Views::Enrollments::Index.new(
      seasons: @seasons,
      enrollments_by_season: @enrollments_by_season,
      courses: @courses
    )
  end

  def dashboard
    @credit_stats = Enrollment.credit_stats
    @credits_by_category = Enrollment.credits_by_category

    render Views::Enrollments::Dashboard.new(
      credit_stats: @credit_stats,
      credits_by_category: @credits_by_category
    )
  end

  def new
    @enrollment = Enrollment.new(season_key: params[:season_key])
    @seasons = Season.upcoming(4)
    @courses = Course.all

    render Views::Enrollments::New.new(
      enrollment: @enrollment,
      seasons: @seasons,
      courses: @courses
    )
  end

  def create
    @enrollment = Enrollment.new(enrollment_params)
    @enrollment.status ||= "planned"

    if @enrollment.save
      redirect_to enrollments_path, notice: "Course added to your plan!"
    else
      @seasons = Season.upcoming(4)
      @courses = Course.all
      render Views::Enrollments::New.new(
        enrollment: @enrollment,
        seasons: @seasons,
        courses: @courses
      ), status: :unprocessable_entity
    end
  end

  def update
    @enrollment = Enrollment.find(params[:id])

    if @enrollment.update(enrollment_params)
      redirect_to enrollments_path, notice: "Course updated!"
    else
      redirect_to enrollments_path, alert: "Failed to update."
    end
  end

  def destroy
    @enrollment = Enrollment.find(params[:id])
    @enrollment.destroy
    redirect_to enrollments_path, notice: "Course removed from plan."
  end

  private

  def enrollment_params
    params.require(:enrollment).permit(:course_key, :season_key, :status)
  end
end
