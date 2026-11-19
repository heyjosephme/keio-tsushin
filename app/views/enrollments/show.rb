# frozen_string_literal: true

module Views
  module Enrollments
    class Show < Views::Base
      include Phlex::Rails::Helpers::LinkTo
      include Phlex::Rails::Helpers::FormWith
      include Phlex::Rails::Helpers::Flash

      def initialize(enrollment:, seasons:)
        @enrollment = enrollment
        @course = enrollment.course
        @season = enrollment.season
        @seasons = seasons
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
              render_danger_zone
            end
          end
        end
      end

      private

      def render_flash_messages
        if flash[:notice]
          div(class: "mb-4 rounded-md bg-success-50 p-4") do
            p(class: "text-sm font-medium text-success-800") { flash[:notice] }
          end
        end

        if flash[:alert]
          div(class: "mb-4 rounded-md bg-danger-50 p-4") do
            p(class: "text-sm font-medium text-danger-800") { flash[:alert] }
          end
        end
      end

      def render_back_link
        div(class: "mb-6") do
          link_to(
            t(".back"),
            enrollments_path,
            class: "text-sm text-primary-700 hover:text-primary-900"
          )
        end
      end

      def render_course_header
        div(class: "bg-white rounded-lg shadow p-6 mb-6") do
          div(class: "flex items-start justify-between") do
            div do
              h1(class: "text-2xl font-bold text-gray-900") { @enrollment.localized_name }
              p(class: "text-lg text-gray-500 mt-1") { @enrollment.secondary_name } if @enrollment.secondary_name
            end
            render Components::StatusBadge.new(@enrollment.status, size: :md)
          end

          div(class: "mt-4 flex flex-wrap gap-3") do
            render_tag(t("shared.credits", count: @enrollment.credits), "bg-gray-100 text-gray-700")
            render Components::FieldTag.new(@course, size: :md)
            render_tag(@course.type_label, "bg-gray-100 text-gray-700") if @course.type
          end
        end
      end

      def render_status_section
        div(class: "bg-white rounded-lg shadow p-6 mb-6") do
          h2(class: "text-lg font-semibold text-gray-900 mb-4") { t(".status") }

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
                Enrollment::STATUSES.map { |s| [ t("shared.statuses.#{s}"), s ] },
                { selected: @enrollment.status },
                class: "border-gray-300 rounded-md shadow-sm text-sm"
              )
              f.submit(t(".update_status"),
                class: "px-4 py-2 bg-primary-800 text-white text-sm rounded-md hover:bg-primary-700 cursor-pointer")
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
          div(class: "flex-1 h-0.5 #{is_done ? 'bg-primary-800' : 'bg-gray-200'}")
        end

        # Step circle
        div(class: "flex flex-col items-center") do
          div(
            class: [
              "w-8 h-8 rounded-full flex items-center justify-center text-xs font-medium",
              if is_current
                "bg-primary-800 text-white ring-2 ring-primary-300"
              elsif is_done
                "bg-primary-800 text-white"
              else
                "bg-gray-200 text-gray-500"
              end
            ].join(" ")
          ) do
            is_done && !is_current ? render(Components::Icon.new(:check, class: "size-4 shrink-0", stroke_width: "2.5")) : plain((index + 1).to_s)
          end
          p(class: "text-xs mt-1 #{is_current ? 'text-primary-700 font-medium' : 'text-gray-500'} whitespace-nowrap") do
            t("shared.statuses.#{status}")
          end
        end
      end

      def render_season_section
        div(class: "bg-white rounded-lg shadow p-6 mb-6") do
          h2(class: "text-lg font-semibold text-gray-900 mb-4") { t(".exam_season") }

          if @season
            div(class: "grid grid-cols-1 sm:grid-cols-3 gap-4 mb-4") do
              render_date_card(t(".report_deadline"), @season.report_deadline, @season.days_until_report_deadline)
              render_date_card(t(".application_deadline"), @season.application_deadline, @season.days_until_application_deadline)
              render_date_card(t(".exam_period"), @season.exam_start, nil, @season.exam_end)
            end
          end

          # Season change form
          form_with(model: @enrollment, method: :patch, class: "mt-4") do |f|
            div(class: "flex items-center gap-3") do
              label(class: "text-sm text-gray-600") { t(".move_to") }
              f.select(
                :season_key,
                @seasons.map { |s| [ s.label, s.key ] },
                { selected: @enrollment.season_key },
                class: "border-gray-300 rounded-md shadow-sm text-sm"
              )
              f.submit(t(".move"),
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
              plain t("shared.date_range", from: l(date, format: :month_day), to: l(end_date, format: :full))
            else
              plain l(date, format: :full)
            end
          end

          if days_until && days_until >= 0 && days_until <= 30
            color = case days_until
            when 0..3 then "text-danger-600"
            when 4..7 then "text-warning-600"
            else "text-gray-500"
            end
            p(class: "text-xs mt-1 #{color}") do
              days_until == 0 ? t(".today") : t(".days_left", count: days_until)
            end
          end
        end
      end

      def render_reference_links
        div(class: "bg-white rounded-lg shadow p-6 mb-6") do
          h2(class: "text-lg font-semibold text-gray-900 mb-4") { t("shared.references.title") }

          div(class: "space-y-3") do
            if @course.syllabus_page
              link_to(
                documents_path(pdf: "syllabus", page: @course.syllabus_page),
                class: "flex items-center gap-3 p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition"
              ) do
                render Components::Icon.new(:book, class: "size-5 shrink-0 text-primary-600")
                div do
                  p(class: "text-sm font-medium text-gray-900") { t("shared.references.syllabus") }
                  p(class: "text-xs text-gray-500") { t("shared.page", page: @course.syllabus_page) }
                end
              end
            end

            if @course.report_page
              link_to(
                documents_path(pdf: @course.report_pdf, page: @course.report_page),
                class: "flex items-center gap-3 p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition"
              ) do
                render Components::Icon.new(:report, class: "size-5 shrink-0 text-primary-600")
                div do
                  p(class: "text-sm font-medium text-gray-900") { t("shared.references.report_guide") }
                  p(class: "text-xs text-gray-500") { t("shared.page", page: @course.report_page) }
                end
              end
            end
          end
        end
      end

      def render_danger_zone
        div(class: "bg-white rounded-lg shadow p-6 border border-danger-100") do
          h2(class: "text-lg font-semibold text-gray-900 mb-2") { t(".danger_zone") }
          p(class: "text-sm text-gray-500 mb-4") { t(".danger_text") }

          form_with(url: enrollment_path(@enrollment), method: :delete) do
            button(
              type: "submit",
              class: "px-4 py-2 bg-danger-600 text-white text-sm rounded-md hover:bg-danger-700 cursor-pointer",
              data: { turbo_confirm: t(".remove_confirm", course: @enrollment.localized_name) }
            ) { t(".remove") }
          end
        end
      end

      # Helpers

      def render_tag(text, color_class)
        span(class: "px-3 py-1 rounded-full text-sm font-medium #{color_class}") { text }
      end
    end
  end
end
