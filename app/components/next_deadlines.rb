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
      render_card("Next report deadline", "レポート提出締切", @report)
      render_card("Next exam application deadline", "試験申込締切", @application)
    end
  end

  private

  def render_card(label, label_ja, event)
    days = event&.days_left(@today)

    div(class: "bg-white rounded-lg shadow p-4 border-l-4 #{border_color(days)}") do
      p(class: "text-xs font-medium text-gray-500 uppercase tracking-wide") do
        plain label
        span(class: "ml-2 normal-case text-gray-400") { label_ja }
      end

      if event
        div(class: "mt-2 flex items-end justify-between gap-4") do
          div do
            p(class: "text-xl font-semibold text-gray-900") { event.date.strftime("%a, %b %-d, %Y") }
            p(class: "text-sm text-gray-500") { "#{event.season.name} exams" }
          end
          span(class: "px-2 py-1 rounded text-sm font-medium whitespace-nowrap #{badge_color(days)}") { days_text(days) }
        end
      else
        p(class: "mt-2 text-sm text-gray-500") { "Not announced yet" }
      end
    end
  end

  def days_text(days)
    case days
    when 0 then "Today"
    when 1 then "Tomorrow"
    else "#{days} days left"
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
