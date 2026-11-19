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

    div(class: "bg-white rounded-lg shadow p-4 border-l-4 #{border_color(days)}") do
      p(class: "text-xs font-medium text-gray-500 uppercase tracking-wide") { label }

      if event
        div(class: "mt-2 flex items-end justify-between gap-4") do
          div do
            p(class: "text-xl font-semibold text-gray-900") { l(event.date, format: :full_weekday) }
            p(class: "text-sm text-gray-500") do
              plain t("shared.season_exams", season: event.season.name)
              span(class: "ml-2 px-1.5 py-0.5 rounded text-xs font-normal bg-amber-100 text-amber-800") { t("shared.estimated") } if event.estimated?
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
    when 0..3 then "border-red-500"
    when 4..7 then "border-yellow-500"
    else "border-indigo-500"
    end
  end

  def badge_color(days)
    case days
    when 0..3 then "bg-red-100 text-red-700"
    when 4..7 then "bg-yellow-100 text-yellow-700"
    else "bg-gray-100 text-gray-700"
    end
  end
end
