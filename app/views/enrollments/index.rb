# frozen_string_literal: true

module Views
  module Enrollments
    class Index < Views::Base
      include Phlex::Rails::Helpers::Flash
      include Phlex::Rails::Helpers::LinkTo
      include Phlex::Rails::Helpers::FormWith

      def initialize(seasons:, enrollments_by_season:, courses:)
        @seasons = seasons
        @enrollments_by_season = enrollments_by_season
        @courses = courses
      end

      def view_template
        render Components::Layout.new do
          div(class: "py-8") do
            div(class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8") do
              render_flash_messages
              render_header

              # Kanban board
              div(class: "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4") do
                @seasons.each do |season|
                  render_season_column(season)
                end
              end
            end
          end
        end
      end

      private

      def render_header
        div(class: "mb-8 flex justify-between items-center") do
          h1(class: "text-3xl font-bold text-gray-900") { "Course Planner" }
          link_to(
            "+ Add Course",
            new_enrollment_path,
            class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700"
          )
        end
      end

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

      def render_season_column(season)
        enrollments = @enrollments_by_season[season.key] || []

        div(class: "bg-white rounded-lg shadow") do
          # Season header
          div(class: "p-4 border-b border-gray-200") do
            h2(class: "font-semibold text-gray-900") { season.short_name }
            render_season_dates(season)
          end

          # Enrollments list
          div(class: "p-4 space-y-3 min-h-[200px]") do
            if enrollments.any?
              enrollments.each { |enrollment| render_enrollment_card(enrollment) }
            else
              p(class: "text-gray-400 text-sm text-center py-8") { "No courses" }
            end

            # Add course to this season
            link_to(
              "+ Add",
              new_enrollment_path(season_key: season.key),
              class: "block text-center text-sm text-indigo-600 hover:text-indigo-800 py-2"
            )
          end
        end
      end

      def render_season_dates(season)
        div(class: "mt-2 text-xs text-gray-500 space-y-1") do
          div do
            span(class: "font-medium") { "Report: " }
            span { season.report_deadline.strftime("%b %d") }
            render_days_badge(season.days_until_report_deadline)
          end
          div do
            span(class: "font-medium") { "Apply: " }
            span { season.application_deadline.strftime("%b %d") }
          end
          div do
            span(class: "font-medium") { "Exam: " }
            span { "#{season.exam_start.strftime('%b %d')}-#{season.exam_end.strftime('%d')}" }
          end
        end
      end

      def render_days_badge(days)
        return if days < 0 || days > 30

        color = case days
        when 0..3 then "bg-red-100 text-red-700"
        when 4..7 then "bg-yellow-100 text-yellow-700"
        else "bg-gray-100 text-gray-600"
        end

        span(class: "ml-2 px-1.5 py-0.5 rounded text-xs #{color}") do
          days == 0 ? "Today" : "#{days}d"
        end
      end

      def render_enrollment_card(enrollment)
        course = enrollment.course

        div(class: "bg-gray-50 rounded-lg p-3 border border-gray-200 hover:border-indigo-300 transition") do
          link_to(
            enrollment_path(enrollment),
            class: "block"
          ) do
            div(class: "flex justify-between items-start") do
              div do
                p(class: "font-medium text-gray-900 text-sm hover:text-indigo-600") { enrollment.name }
                p(class: "text-xs text-gray-500") { enrollment.name_ja } if enrollment.name_ja
                p(class: "text-xs text-gray-500 mt-1") do
                  render_status_badge(enrollment.status)
                  span(class: "ml-2") { "#{enrollment.credits}単位" } if enrollment.credits
                end
              end
            end
          end

          # Reference links
          render_reference_links(course) if course&.has_references?

          # Move to another season dropdown
          div(class: "mt-3 flex items-center justify-between") do
            render_move_dropdown(enrollment)
            render_delete_button(enrollment)
          end
        end
      end

      def render_reference_links(course)
        div(class: "mt-2 flex gap-2 text-xs") do
          if course.syllabus_page
            link_to(
              "📄 Syllabus p.#{course.syllabus_page}",
              documents_path(pdf: "syllabus", page: course.syllabus_page),
              class: "text-indigo-600 hover:text-indigo-800"
            )
          end

          if course.report_page
            link_to(
              "📝 Report p.#{course.report_page}",
              documents_path(pdf: "reports", page: course.report_page),
              class: "text-indigo-600 hover:text-indigo-800"
            )
          end
        end
      end

      def render_status_badge(status)
        colors = {
          "planned" => "bg-gray-100 text-gray-600",
          "report_submitted" => "bg-blue-100 text-blue-700",
          "exam_applied" => "bg-yellow-100 text-yellow-700",
          "completed" => "bg-green-100 text-green-700"
        }

        span(class: "px-1.5 py-0.5 rounded text-xs #{colors[status]}") do
          status.titleize
        end
      end

      def render_move_dropdown(enrollment)
        form_with(model: enrollment, method: :patch, class: "inline") do |f|
          f.select(
            :season_key,
            @seasons.map { |s| [ s.short_name, s.key ] },
            { selected: enrollment.season_key },
            class: "text-xs border-gray-300 rounded py-1 pr-8",
            onchange: "this.form.submit()"
          )
        end
      end

      def render_delete_button(enrollment)
        form_with(url: enrollment_path(enrollment), method: :delete, class: "inline") do
          button(
            type: "submit",
            class: "text-xs text-red-600 hover:text-red-800",
            data: { turbo_confirm: "Remove this course?" }
          ) { "Remove" }
        end
      end
    end
  end
end
