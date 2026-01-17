class DeadlinesController < ApplicationController
  def index
    @year = (params[:year] || Date.today.year).to_i
    @month = (params[:month] || Date.today.month).to_i
    @current_date = Date.new(@year, @month, 1)

    @deadlines = current_user_deadlines.where(
      deadline_date: @current_date.beginning_of_month..@current_date.end_of_month
    ).order(:deadline_date)

    @upcoming_deadlines = current_user_deadlines.upcoming.limit(5)

    render Views::Deadlines::Index.new(
      current_date: @current_date,
      deadlines: @deadlines,
      upcoming: @upcoming_deadlines
    )
  end

  def new
    @deadline = current_user_deadlines.new
    render Views::Deadlines::New.new(deadline: @deadline)
  end

  def create
    @deadline = current_user_deadlines.new(deadline_params)

    if @deadline.save
      redirect_to deadlines_path, notice: "Deadline created successfully!"
    else
      render Views::Deadlines::New.new(deadline: @deadline), status: :unprocessable_entity
    end
  end

  def destroy
    @deadline = current_user_deadlines.find(params[:id])
    @deadline.destroy
    redirect_to deadlines_path, notice: "Deadline deleted."
  end

  private

  def current_user_deadlines
    Current.user.deadlines
  end

  def deadline_params
    params.require(:deadline).permit(:course_name, :deadline_date, :deadline_type, :description)
  end
end
