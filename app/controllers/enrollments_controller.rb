class EnrollmentsController < ApplicationController
  def index
    @seasons = Season.upcoming(4)
    @enrollments_by_season = current_user_enrollments.group_by(&:season_key)
    @courses = courses_for_current_user

    render Views::Enrollments::Index.new(
      seasons: @seasons,
      enrollments_by_season: @enrollments_by_season,
      courses: @courses
    )
  end

  def show
    @enrollment = current_user_enrollments.find(params[:id])
    @seasons = Season.upcoming(4)
    @deadlines = Current.user.deadlines.where(course_name: @enrollment.name).upcoming

    render Views::Enrollments::Show.new(
      enrollment: @enrollment,
      seasons: @seasons,
      deadlines: @deadlines
    )
  end

  def dashboard
    @credit_stats = current_user_enrollments.credit_stats
    @credits_by_category = current_user_enrollments.credits_by_category

    render Views::Enrollments::Dashboard.new(
      credit_stats: @credit_stats,
      credits_by_category: @credits_by_category
    )
  end

  def new
    @enrollment = current_user_enrollments.new(season_key: params[:season_key])
    @seasons = Season.upcoming(4)
    @courses = courses_for_current_user

    render Views::Enrollments::New.new(
      enrollment: @enrollment,
      seasons: @seasons,
      courses: @courses
    )
  end

  def create
    @enrollment = current_user_enrollments.new(enrollment_params)
    @enrollment.status ||= "planned"

    if @enrollment.save
      redirect_to enrollments_path, notice: "Course added to your plan!"
    else
      @seasons = Season.upcoming(4)
      @courses = courses_for_current_user
      render Views::Enrollments::New.new(
        enrollment: @enrollment,
        seasons: @seasons,
        courses: @courses
      ), status: :unprocessable_entity
    end
  end

  def update
    @enrollment = current_user_enrollments.find(params[:id])

    if @enrollment.update(enrollment_params)
      redirect_back(fallback_location: enrollment_path(@enrollment), notice: "Course updated!")
    else
      redirect_back(fallback_location: enrollment_path(@enrollment), alert: "Failed to update.")
    end
  end

  def destroy
    @enrollment = current_user_enrollments.find(params[:id])
    @enrollment.destroy
    redirect_to enrollments_path, notice: "Course removed from plan."
  end

  private

  def current_user_enrollments
    Current.user.enrollments
  end

  def courses_for_current_user
    Course.for_major(Current.user.major)
  end

  def enrollment_params
    params.require(:enrollment).permit(:course_key, :season_key, :status)
  end
end
