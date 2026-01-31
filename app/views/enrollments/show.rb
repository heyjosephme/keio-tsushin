# frozen_string_literal: true

module Views
  module Enrollments
    class Show < Views::Base
      include Phlex::Rails::Helpers::LinkTo
      include Phlex::Rails::Helpers::FormWith
      include Phlex::Rails::Helpers::Flash

      def initialize(enrollment:, seasons:, deadlines:)
        @enrollment = enrollment
        @course = enrollment.course
        @season = enrollment.season
        @seasons = seasons
        @deadlines = deadlines
      end

      def view_template
        render Components::Layout.new do
          div(class: "py-8") do
            div(class: "max-w-3xl mx-auto px-4 sm:px-6 lg:px-8") do
              render_flash_messages
              render_back_link
              render_course_header
              render_status_section
              render_season_section
              render_reference_links if @course&.has_references?
              render_deadlines if @deadlines.any?
              render_danger_zone
            end
          end
        end
      end

      private

      def render_flash_messages
        if flash[:notice]
          div(class: "mb-4 rounded-md bg-green-50 p-4") do
            p(class: "text-sm font-medium text-green-800") { flash[:notice] }
          end
        end

        if flash[:alert]
          div(class: "mb-4 rounded-md bg-red-50 p-4") do
            p(class: "text-sm font-medium text-red-800") { flash[:alert] }
          end
        end
      end

      def render_back_link
        div(class: "mb-6") do
          link_to(
            "← Back to Course Planner",
            enrollments_path,
            class: "text-sm text-indigo-600 hover:text-indigo-800"
          )
        end
      end

      def render_course_header
        div(class: "bg-white rounded-lg shadow p-6 mb-6") do
          div(class: "flex items-start justify-between") do
            div do
              h1(class: "text-2xl font-bold text-gray-900") { @enrollment.name }
              p(class: "text-lg text-gray-500 mt-1") { @enrollment.name_ja } if @enrollment.name_ja
            end
            render_status_badge(@enrollment.status)
          end

          div(class: "mt-4 flex flex-wrap gap-3") do
            render_tag("#{@enrollment.credits} credits", "bg-indigo-50 text-indigo-700")
            render_tag(@course.category_label, category_color(@course.category))
            render_tag(@course.type.titleize, "bg-gray-50 text-gray-700") if @course.type
          end
        end
      end

      def render_status_section
        div(class: "bg-white rounded-lg shadow p-6 mb-6") do
          h2(class: "text-lg font-semibold text-gray-900 mb-4") { "Status" }

          # Status progression
          div(class: "flex items-center gap-2 mb-4") do
            Enrollment::STATUSES.each_with_index do |s, i|
              render_status_step(s, i)
            end
          end

          # Status change form
          form_with(model: @enrollment, method: :patch, class: "mt-4") do |f|
            div(class: "flex items-center gap-3") do
              f.select(
                :status,
                Enrollment::STATUSES.map { |s| [s.titleize, s] },
                { selected: @enrollment.status },
                class: "border-gray-300 rounded-md shadow-sm text-sm"
              )
              f.submit("Update Status",
                class: "px-4 py-2 bg-indigo-600 text-white text-sm rounded-md hover:bg-indigo-700 cursor-pointer")
            end
          end
        end
      end

      def render_status_step(status, index)
        current_index = Enrollment::STATUSES.index(@enrollment.status)
        is_done = index <= current_index
        is_current = index == current_index

        # Connector line (between steps)
        if index > 0
          div(class: "flex-1 h-0.5 #{is_done ? 'bg-indigo-600' : 'bg-gray-200'}")
        end

        # Step circle
        div(class: "flex flex-col items-center") do
          div(
            class: [
              "w-8 h-8 rounded-full flex items-center justify-center text-xs font-medium",
              if is_current
                "bg-indigo-600 text-white ring-2 ring-indigo-300"
              elsif is_done
                "bg-indigo-600 text-white"
              else
                "bg-gray-200 text-gray-500"
              end
            ].join(" ")
          ) do
            is_done && !is_current ? plain("✓") : plain((index + 1).to_s)
          end
          p(class: "text-xs mt-1 #{is_current ? 'text-indigo-600 font-medium' : 'text-gray-500'} whitespace-nowrap") do
            status.titleize
          end
        end
      end

      def render_season_section
        div(class: "bg-white rounded-lg shadow p-6 mb-6") do
          h2(class: "text-lg font-semibold text-gray-900 mb-4") { "Exam Season" }

          if @season
            div(class: "grid grid-cols-1 sm:grid-cols-3 gap-4 mb-4") do
              render_date_card("Report Deadline", @season.report_deadline, @season.days_until_report_deadline)
              render_date_card("Application Deadline", @season.application_deadline, @season.days_until_application_deadline)
              render_date_card("Exam Period", @season.exam_start, nil, @season.exam_end)
            end
          end

          # Season change form
          form_with(model: @enrollment, method: :patch, class: "mt-4") do |f|
            div(class: "flex items-center gap-3") do
              label(class: "text-sm text-gray-600") { "Move to:" }
              f.select(
                :season_key,
                @seasons.map { |s| [s.short_name, s.key] },
                { selected: @enrollment.season_key },
                class: "border-gray-300 rounded-md shadow-sm text-sm"
              )
              f.submit("Move",
                class: "px-4 py-2 bg-gray-600 text-white text-sm rounded-md hover:bg-gray-700 cursor-pointer")
            end
          end
        end
      end

      def render_date_card(label, date, days_until = nil, end_date = nil)
        div(class: "bg-gray-50 rounded-lg p-4") do
          p(class: "text-xs font-medium text-gray-500 uppercase tracking-wide") { label }
          p(class: "text-sm font-semibold text-gray-900 mt-1") do
            if end_date
              plain "#{date.strftime('%b %d')} - #{end_date.strftime('%b %d, %Y')}"
            else
              plain date.strftime("%b %d, %Y")
            end
          end

          if days_until && days_until >= 0 && days_until <= 30
            color = case days_until
            when 0..3 then "text-red-600"
            when 4..7 then "text-yellow-600"
            else "text-gray-500"
            end
            p(class: "text-xs mt-1 #{color}") do
              days_until == 0 ? "Today!" : "#{days_until} days left"
            end
          end
        end
      end

      def render_reference_links
        div(class: "bg-white rounded-lg shadow p-6 mb-6") do
          h2(class: "text-lg font-semibold text-gray-900 mb-4") { "Study References" }

          div(class: "space-y-3") do
            if @course.syllabus_page
              link_to(
                helpers.documents_path(pdf: "syllabus", page: @course.syllabus_page),
                class: "flex items-center gap-3 p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition"
              ) do
                span(class: "text-lg") { "📄" }
                div do
                  p(class: "text-sm font-medium text-gray-900") { "Syllabus" }
                  p(class: "text-xs text-gray-500") { "Page #{@course.syllabus_page}" }
                end
              end
            end

            if @course.report_page
              link_to(
                helpers.documents_path(pdf: "reports", page: @course.report_page),
                class: "flex items-center gap-3 p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition"
              ) do
                span(class: "text-lg") { "📝" }
                div do
                  p(class: "text-sm font-medium text-gray-900") { "Report Guide" }
                  p(class: "text-xs text-gray-500") { "Page #{@course.report_page}" }
                end
              end
            end
          end
        end
      end

      def render_deadlines
        div(class: "bg-white rounded-lg shadow p-6 mb-6") do
          h2(class: "text-lg font-semibold text-gray-900 mb-4") { "Upcoming Deadlines" }

          div(class: "space-y-3") do
            @deadlines.each do |deadline|
              div(class: "flex items-center justify-between p-3 bg-gray-50 rounded-lg") do
                div do
                  p(class: "text-sm font-medium text-gray-900") { deadline.description || deadline.deadline_type.titleize }
                  p(class: "text-xs text-gray-500") { deadline.deadline_date.strftime("%B %d, %Y") }
                end
                render_deadline_type_badge(deadline.deadline_type)
              end
            end
          end
        end
      end

      def render_danger_zone
        div(class: "bg-white rounded-lg shadow p-6 border border-red-100") do
          h2(class: "text-lg font-semibold text-gray-900 mb-2") { "Danger Zone" }
          p(class: "text-sm text-gray-500 mb-4") { "Remove this course from your plan." }

          form_with(url: helpers.enrollment_path(@enrollment), method: :delete) do
            button(
              type: "submit",
              class: "px-4 py-2 bg-red-600 text-white text-sm rounded-md hover:bg-red-700 cursor-pointer",
              data: { turbo_confirm: "Remove #{@enrollment.name} from your plan? This cannot be undone." }
            ) { "Remove Course" }
          end
        end
      end

      # Helpers

      def render_status_badge(status)
        colors = {
          "planned" => "bg-gray-100 text-gray-700",
          "report_submitted" => "bg-blue-100 text-blue-700",
          "exam_applied" => "bg-yellow-100 text-yellow-700",
          "completed" => "bg-green-100 text-green-700"
        }

        span(class: "px-3 py-1 rounded-full text-sm font-medium #{colors[status]}") do
          status.titleize
        end
      end

      def render_tag(text, color_class)
        span(class: "px-3 py-1 rounded-full text-sm font-medium #{color_class}") { text }
      end

      def render_deadline_type_badge(type)
        color = type == "report" ? "bg-blue-100 text-blue-700" : "bg-red-100 text-red-700"
        span(class: "px-2 py-1 rounded text-xs font-medium #{color}") { type.titleize }
      end

      def category_color(category)
        {
          "required" => "bg-red-50 text-red-700",
          "elective" => "bg-purple-50 text-purple-700",
          "foreign_language" => "bg-teal-50 text-teal-700",
          "physical_education" => "bg-orange-50 text-orange-700"
        }[category] || "bg-gray-50 text-gray-700"
      end
    end
  end
end
