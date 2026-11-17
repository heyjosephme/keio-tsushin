class DeadlinesController < ApplicationController
  # The calendar is read-only: every date comes from config/seasons.yml (see Season.events).
  def index
    @current_date = requested_month

    render Views::Deadlines::Index.new(
      current_date: @current_date,
      events: Season.events_in(@current_date.all_month)
    )
  end

  private

  def requested_month
    today = Date.today
    Date.new((params[:year] || today.year).to_i, (params[:month] || today.month).to_i, 1)
  rescue Date::Error
    today.beginning_of_month
  end
end
