# frozen_string_literal: true

class Components::Calendar < Components::Base
  DAYS_OF_WEEK = %w[Mon Tue Wed Thu Fri Sat Sun].freeze

  PILL_COLORS = {
    "report" => "bg-blue-100 text-blue-700",
    "application" => "bg-yellow-100 text-yellow-700",
    "exam" => "bg-red-100 text-red-700"
  }.freeze
  DETAIL_COLORS = {
    "report" => "border-blue-300 bg-blue-50",
    "application" => "border-yellow-300 bg-yellow-50",
    "exam" => "border-red-300 bg-red-50"
  }.freeze

  # events: Season::Event objects for the displayed month
  def initialize(current_date:, events:)
    @current_date = current_date
    @events_by_date = events.group_by(&:date)
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
    day_events = @events_by_date[date] || []
    has_events = day_events.any?

    div(
      class: "relative h-24 border border-gray-100 rounded-lg p-1 #{is_today ? 'bg-indigo-50 border-indigo-300' : 'hover:bg-gray-50'} #{has_events ? 'cursor-pointer' : ''}",
      data: has_events ? { controller: "calendar-cell", action: "click->calendar-cell#toggle" } : {}
    ) do
      # Day number
      span(
        class: "text-sm font-medium #{is_today ? 'text-indigo-600' : 'text-gray-700'}"
      ) { day.to_s }

      if has_events
        div(class: "mt-1 space-y-1") do
          day_events.each { |event| render_event_pill(event) }
        end

        # Hidden details panel (shown on click)
        render_day_details(date, day_events)
      end
    end
  end

  def render_day_details(date, events)
    div(
      class: "hidden absolute z-10 left-0 top-full mt-1 w-64 bg-white border border-gray-200 rounded-lg shadow-lg p-3",
      data: { calendar_cell_target: "details" }
    ) do
      h4(class: "font-medium text-gray-900 mb-2") { date.strftime("%B %d, %Y") }
      div(class: "space-y-2") do
        events.each do |event|
          div(class: "border-l-2 pl-2 py-1 #{DETAIL_COLORS.fetch(event.type)}") do
            p(class: "text-sm font-medium text-gray-900") { event.title }
            p(class: "text-xs text-gray-600") { "#{event.season.name} exams" }
          end
        end
      end
    end
  end

  def render_event_pill(event)
    div(class: "text-xs px-1 py-0.5 rounded truncate #{PILL_COLORS.fetch(event.type)}") do
      event.short_title
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
