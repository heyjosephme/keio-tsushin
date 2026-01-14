class DeadlinesController < ApplicationController
  def index
    @deadlines = Deadline.all.order(:deadline_date)
    @upcoming_deadlines = Deadline.upcoming
    @past_deadlines = Deadline.past

    render Views::Deadlines::Index.new(
      deadlines: @deadlines,
      upcoming: @upcoming_deadlines,
      past: @past_deadlines
    )
  end

  def new
    @deadline = Deadline.new
    render Views::Deadlines::New.new(deadline: @deadline)
  end

  def create
    @deadline = Deadline.new(deadline_params)

    if @deadline.save
      redirect_to deadlines_path, notice: "Deadline created successfully!"
    else
      render Views::Deadlines::New.new(deadline: @deadline), status: :unprocessable_entity
    end
  end

  def destroy
    @deadline = Deadline.find(params[:id])
    @deadline.destroy
    redirect_to deadlines_path, notice: "Deadline deleted."
  end

  private

  def deadline_params
    params.require(:deadline).permit(:course_name, :deadline_date, :deadline_type, :description)
  end
end
