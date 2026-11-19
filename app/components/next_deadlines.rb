# frozen_string_literal: true

# Shows the next report submission deadline and the next exam application deadline.
# Both come from config/seasons.yml and are the same for every student.
class Components::NextDeadlines < Components::Base
  def initialize(today: Date.today)
    @today = today
    @report = Season.next_event("report", from: today)
    @application = Season.next_event("application", from: today)
  end

  def view_template
    div(class: "grid grid-cols-1 sm:grid-cols-2 gap-4") do
      render_card(t(".report"), @report)
      render_card(t(".application"), @application)
    end
  end

  private

  def render_card(label, event)
    days = event&.days_left(@today)

    div(class: "bg-white rounded-lg shadow-sm ring-1 ring-primary-100 p-4 border-l-4 #{border_color(days)}") do
      p(class: "text-xs font-medium text-gray-500 uppercase tracking-wide") { label }

      if event
        div(class: "mt-2 flex items-end justify-between gap-4") do
          div do
            p(class: "text-xl font-semibold text-primary-900") { l(event.date, format: :full_weekday) }
            p(class: "text-sm text-gray-500") do
              plain t("shared.season_exams", season: event.season.exam_name)
              span(class: "ml-2 px-1.5 py-0.5 rounded text-xs border border-dashed border-gray-400 text-gray-600") { t("shared.estimated") } if event.estimated?
            end
          end
          span(class: "px-2 py-1 rounded text-sm font-medium whitespace-nowrap #{badge_color(days)}") { days_text(days) }
        end
      else
        p(class: "mt-2 text-sm text-gray-500") { t(".not_announced") }
      end
    end
  end

  def days_text(days)
    case days
    when 0 then t("shared.today")
    when 1 then t(".tomorrow")
    else t(".days_left", count: days)
    end
  end

  def border_color(days)
    case days
    when nil then "border-gray-200"
    when 0..3 then "border-danger-600"
    when 4..7 then "border-warning-600"
    else "border-primary-700"
    end
  end

  def badge_color(days)
    case days
    when 0..3 then "bg-danger-100 text-danger-700"
    when 4..7 then "bg-warning-100 text-warning-700"
    else "bg-primary-50 text-primary-800"
    end
  end
end
