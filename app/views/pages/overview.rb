# frozen_string_literal: true

module Views
  module Pages
    # The home page for signed-in users: what each course needs next, the next
    # deadlines, and credit progress. Visitors see Views::Pages::Home instead.
    class Overview < Views::Base
      include Phlex::Rails::Helpers::Flash
      include Phlex::Rails::Helpers::LinkTo
      include Phlex::Rails::Helpers::ButtonTo

      URGENCY = {
        overdue: "border-red-500",
        soon: "border-yellow-500",
        later: "border-gray-200"
      }.freeze

      def initialize(user:, steps:, credit_stats:, any_enrollments:)
        @user = user
        @steps = steps
        @credit_stats = credit_stats
        @any_enrollments = any_enrollments
      end

      def view_template
        render Components::Layout.new do
          div(class: "py-8") do
            div(class: "max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 space-y-6") do
              render_flash_messages
              h1(class: "text-3xl font-bold text-gray-900") do
                @user.name.present? ? t(".greeting", name: @user.name) : t(".title")
              end

              render Components::NextDeadlines.new

              if @any_enrollments
                render_next_steps
                render_credit_progress
              else
                render_empty_state
              end
            end
          end
        end
      end

      private

      def render_flash_messages
        if flash[:notice]
          div(class: "rounded-md bg-green-50 p-4") do
            p(class: "text-sm font-medium text-green-800") { flash[:notice] }
          end
        end

        if flash[:alert]
          div(class: "rounded-md bg-red-50 p-4") do
            p(class: "text-sm font-medium text-red-800") { flash[:alert] }
          end
        end
      end

      def render_next_steps
        section(class: "bg-white rounded-lg shadow p-6") do
          div(class: "flex items-center justify-between mb-4") do
            h2(class: "text-lg font-semibold text-gray-900") { t(".next_steps") }
            link_to(t(".open_planner"), enrollments_path, class: "text-sm text-indigo-600 hover:text-indigo-800")
          end

          if @steps.any?
            div(class: "space-y-5") do
              @steps.group_by { |step| [ step.action, step.date, step.enrollment.season_key ] }.each_value do |steps|
                render_step_group(steps)
              end
            end
          else
            p(class: "text-sm text-gray-500") { t(".all_done") }
          end
        end
      end

      # Courses that share a deadline are listed under one heading
      def render_step_group(steps)
        step = steps.first

        div(class: "border-l-4 #{URGENCY.fetch(urgency(step))} pl-4 py-1") do
          p(class: "text-sm font-medium text-gray-900") { step_text(step) }
          p(class: "text-xs text-gray-400 mb-2") { t("shared.season_exams", season: step.enrollment.season.name) }

          div(class: "divide-y divide-gray-100") do
            steps.each { |course_step| render_course_row(course_step) }
          end
        end
      end

      def render_course_row(step)
        enrollment = step.enrollment

        div(class: "flex flex-wrap items-center justify-between gap-3 py-2") do
          link_to(enrollment.localized_name, enrollment_path(enrollment), class: "text-sm text-gray-700 hover:text-indigo-600")

          if step.action == :reschedule
            link_to(t(".move"), enrollment_path(enrollment), class: "text-sm font-medium text-red-600 hover:text-red-800")
          else
            button_to(
              t(".mark.#{step.next_status}"),
              enrollment_path(enrollment),
              method: :patch,
              params: { enrollment: { status: step.next_status } },
              class: "px-3 py-1.5 text-sm font-medium rounded-md border border-gray-300 text-gray-700 bg-white hover:bg-gray-50 cursor-pointer"
            )
          end
        end
      end

      def step_text(step)
        date = l(step.date, format: :full_weekday)

        case step.action
        when :reschedule, :record_result then t(".steps.#{step.action}", date: date)
        else "#{t(".steps.#{step.action}", date: date)} · #{days_text(step.days_left)}"
        end
      end

      def days_text(days)
        case days
        when 0 then t("shared.today")
        when 1 then t(".tomorrow")
        else t(".days_left", count: days)
        end
      end

      def urgency(step)
        return :overdue if step.action == :reschedule || step.days_left <= 3
        return :later if step.action == :record_result

        step.days_left <= 14 ? :soon : :later
      end

      def render_credit_progress
        required = Enrollment::CREDITS_REQUIRED
        completed = @credit_stats[:completed]

        section(class: "bg-white rounded-lg shadow p-6") do
          div(class: "flex items-center justify-between mb-4") do
            h2(class: "text-lg font-semibold text-gray-900") { t(".credits_title") }
            link_to(t(".view_dashboard"), dashboard_enrollments_path, class: "text-sm text-indigo-600 hover:text-indigo-800")
          end

          p(class: "text-sm text-gray-700 mb-2") { t(".credits_summary", completed: completed, required: required) }
          div(class: "w-full bg-gray-200 rounded-full h-3 flex overflow-hidden") do
            div(class: "bg-indigo-600 h-3", style: "width: #{percent(completed)}%")
            div(class: "bg-indigo-300 h-3", style: "width: #{percent(@credit_stats[:in_progress])}%")
            div(class: "bg-indigo-100 h-3", style: "width: #{percent(@credit_stats[:planned])}%")
          end
          p(class: "mt-2 text-xs text-gray-500") do
            t(".credits_breakdown", in_progress: @credit_stats[:in_progress], planned: @credit_stats[:planned])
          end
        end
      end

      def percent(credits)
        [ credits * 100.0 / Enrollment::CREDITS_REQUIRED, 100 ].min.round(1)
      end

      def render_empty_state
        section(class: "bg-white rounded-lg shadow p-8 text-center") do
          h2(class: "text-lg font-semibold text-gray-900 mb-2") { t(".empty_title") }
          p(class: "text-sm text-gray-600 mb-5") { t(@user.major.present? ? ".empty_text" : ".empty_text_no_major") }

          div(class: "flex flex-wrap justify-center gap-3") do
            link_to(t(".browse"), catalog_path, class: "px-4 py-2 rounded-md text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700")
            unless @user.major.present?
              link_to(t(".set_major"), edit_profile_path, class: "px-4 py-2 rounded-md text-sm font-medium border border-gray-300 text-gray-700 bg-white hover:bg-gray-50")
            end
          end
        end
      end
    end
  end
end
