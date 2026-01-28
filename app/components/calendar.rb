# frozen_string_literal: true

class Components::Calendar < Components::Base
  DAYS_OF_WEEK = %w[Mon Tue Wed Thu Fri Sat Sun].freeze

  def initialize(current_date:, deadlines:)
    @current_date = current_date
    @deadlines = deadlines
    @deadlines_by_date = deadlines.group_by(&:deadline_date)
  end

  def view_template
    div(class: "bg-white rounded-lg shadow p-6") do
      render_header
      render_days_of_week
      render_calendar_grid
    end
  end

  private

  def render_header
    div(class: "flex items-center justify-between mb-6") do
      a(
        href: deadlines_path(month: prev_month.month, year: prev_month.year),
        class: "p-2 hover:bg-gray-100 rounded-lg text-gray-600"
      ) { "←" }

      h2(class: "text-xl font-semibold text-gray-900") do
        @current_date.strftime("%B %Y")
      end

      a(
        href: deadlines_path(month: next_month.month, year: next_month.year),
        class: "p-2 hover:bg-gray-100 rounded-lg text-gray-600"
      ) { "→" }
    end
  end

  def render_days_of_week
    div(class: "grid grid-cols-7 gap-1 mb-2") do
      DAYS_OF_WEEK.each do |day|
        div(class: "text-center text-sm font-medium text-gray-500 py-2") { day }
      end
    end
  end

  def render_calendar_grid
    div(class: "grid grid-cols-7 gap-1") do
      # Empty cells for days before the month starts
      start_day = (@current_date.beginning_of_month.wday + 6) % 7 # Monday = 0
      start_day.times { div(class: "h-24") }

      # Days of the month
      (1..days_in_month).each do |day|
        render_day(day)
      end
    end
  end

  def render_day(day)
    date = Date.new(@current_date.year, @current_date.month, day)
    is_today = date == Date.today
    day_deadlines = @deadlines_by_date[date] || []
    has_deadlines = day_deadlines.any?

    div(
      class: "relative h-24 border border-gray-100 rounded-lg p-1 #{is_today ? 'bg-indigo-50 border-indigo-300' : 'hover:bg-gray-50'} #{has_deadlines ? 'cursor-pointer' : ''}",
      data: has_deadlines ? { controller: "calendar-cell", action: "click->calendar-cell#toggle" } : {}
    ) do
      # Day number
      span(
        class: "text-sm font-medium #{is_today ? 'text-indigo-600' : 'text-gray-700'}"
      ) { day.to_s }

      # Deadline indicators (summary)
      if has_deadlines
        div(class: "mt-1 space-y-1") do
          day_deadlines.first(2).each do |deadline|
            render_deadline_pill(deadline)
          end
          if day_deadlines.size > 2
            span(class: "text-xs text-gray-500") { "+#{day_deadlines.size - 2} more" }
          end
        end

        # Hidden details panel (shown on click)
        render_day_details(date, day_deadlines)
      end
    end
  end

  def render_day_details(date, deadlines)
    div(
      class: "hidden absolute z-10 left-0 top-full mt-1 w-64 bg-white border border-gray-200 rounded-lg shadow-lg p-3",
      data: { calendar_cell_target: "details" }
    ) do
      h4(class: "font-medium text-gray-900 mb-2") { date.strftime("%B %d, %Y") }
      div(class: "space-y-2") do
        deadlines.each do |deadline|
          render_deadline_detail(deadline)
        end
      end
    end
  end

  def render_deadline_detail(deadline)
    color = case deadline.deadline_type
    when "exam" then "border-red-300 bg-red-50"
    when "application" then "border-yellow-300 bg-yellow-50"
    else "border-blue-300 bg-blue-50"
    end

    div(class: "border-l-2 pl-2 py-1 #{color}") do
      p(class: "text-sm font-medium text-gray-900") { deadline.course_name }
      p(class: "text-xs text-gray-600") { deadline.description }
      span(class: "text-xs text-gray-500 capitalize") { deadline.deadline_type }
    end
  end

  def render_deadline_pill(deadline)
    color = deadline.deadline_type == "exam" ? "bg-red-100 text-red-700" : "bg-blue-100 text-blue-700"
    div(class: "text-xs px-1 py-0.5 rounded truncate #{color}") do
      deadline.course_name.truncate(15)
    end
  end

  def prev_month
    @current_date.prev_month
  end

  def next_month
    @current_date.next_month
  end

  def days_in_month
    @current_date.end_of_month.day
  end
end
