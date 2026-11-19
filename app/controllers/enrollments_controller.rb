class EnrollmentsController < ApplicationController
  def index
    @seasons = Season.upcoming(4)
    @enrollments_by_season = current_user_enrollments.group_by(&:season_key)
    @courses = courses_for_current_user

    render Views::Enrollments::Index.new(
      seasons: @seasons,
      enrollments_by_season: @enrollments_by_season,
      courses: @courses,
      undecided_courses: undecided_required_courses,
      past_seasons: Season.past.select { |season| @enrollments_by_season.key?(season.key) },
      major_set: Current.user.major.present?
    )
  end

  def show
    @enrollment = current_user_enrollments.find(params[:id])
    @seasons = Season.upcoming(4)

    render Views::Enrollments::Show.new(
      enrollment: @enrollment,
      seasons: @seasons
    )
  end

  def dashboard
    @credit_stats = current_user_enrollments.credit_stats
    @credits_by_field = current_user_enrollments.credits_by_field

    render Views::Enrollments::Dashboard.new(
      credit_stats: @credit_stats,
      credits_by_field: @credits_by_field,
      graduation: GraduationCheck.new(user: Current.user, enrollments: current_user_enrollments)
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
      redirect_to enrollments_path, notice: t(".success")
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
      redirect_back(fallback_location: enrollment_path(@enrollment), notice: t(".success"))
    else
      redirect_back(fallback_location: enrollment_path(@enrollment), alert: t(".failure"))
    end
  end

  def destroy
    @enrollment = current_user_enrollments.find(params[:id])
    @enrollment.destroy
    redirect_to enrollments_path, notice: t(".success")
  end

  private

  def current_user_enrollments
    Current.user.enrollments
  end

  def courses_for_current_user
    Course.for_major(Current.user.major)
  end

  # Compulsory courses for the user's major that aren't in the plan yet
  def undecided_required_courses
    planned_keys = current_user_enrollments.pluck(:course_key)
    Course.required_for_major(Current.user.major).reject { |course| planned_keys.include?(course.key) }
  end

  def enrollment_params
    params.require(:enrollment).permit(:course_key, :season_key, :status)
  end
end
