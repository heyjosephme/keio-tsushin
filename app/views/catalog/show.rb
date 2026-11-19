# frozen_string_literal: true

module Views
  module Catalog
    class Show < Views::Base
      include Phlex::Rails::Helpers::LinkTo
      include Phlex::Rails::Helpers::FormWith
      include Phlex::Rails::Helpers::Flash

      def initialize(course:, seasons:, existing_enrollment:)
        @course = course
        @seasons = seasons
        @existing_enrollment = existing_enrollment
      end

      def view_template
        render Components::Layout.new do
          div(class: "py-8") do
            div(class: "max-w-3xl mx-auto px-4 sm:px-6 lg:px-8") do
              render_flash_messages
              render_back_link
              render_course_header
              render_details
              render_exam_schedule if @course.exam_group
              render_references if @course.has_references?
              render_add_to_plan_section
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
            t(".back"),
            catalog_path,
            class: "text-sm text-indigo-600 hover:text-indigo-800"
          )
        end
      end

      def render_course_header
        div(class: "bg-white rounded-lg shadow p-6 mb-6") do
          h1(class: "text-2xl font-bold text-gray-900") { @course.localized_name }
          p(class: "text-lg text-gray-500 mt-1") { @course.secondary_name } if @course.secondary_name

          div(class: "mt-4 flex flex-wrap gap-2") do
            tag(t("shared.credits", count: @course.credits), "bg-indigo-50 text-indigo-700")
            tag(@course.field_label, field_color(@course.field))
            tag(@course.type_label, "bg-gray-100 text-gray-700") if @course.type
            tag(exam_group_label, "bg-amber-50 text-amber-700") if @course.exam_group
          end
        end
      end

      def render_details
        div(class: "bg-white rounded-lg shadow p-6 mb-6") do
          h2(class: "text-lg font-semibold text-gray-900 mb-4") { t(".details") }

          dl(class: "grid grid-cols-1 sm:grid-cols-2 gap-4 text-sm") do
            detail_row(t(".course_key"), @course.key)
            detail_row(t(".credits"), @course.credits.to_s)
            detail_row(t(".field"), @course.field_label)
            detail_row(t(".type"), @course.type_label || "—")
            detail_row(t(".available_to"), @course.major_labels.join(", "))
            detail_row(t(".exam_group"), @course.exam_group ? exam_group_label : t(".not_assigned"))
          end
        end
      end

      def exam_group_label
        t("shared.exam_group", group: @course.exam_group)
      end

      def detail_row(label, value)
        div do
          dt(class: "text-xs font-medium text-gray-500 uppercase tracking-wide") { label }
          dd(class: "mt-1 text-gray-900") { value }
        end
      end

      def render_exam_schedule
        # Show schedule for next upcoming season of each type
        apr_jul_season = @seasons.find { |s| s.season_type == "apr_jul" }
        oct_jan_season = @seasons.find { |s| s.season_type == "oct_jan" }

        div(class: "bg-white rounded-lg shadow p-6 mb-6") do
          h2(class: "text-lg font-semibold text-gray-900 mb-4") { t(".exam_schedule") }
          p(class: "text-sm text-gray-500 mb-4") do
            t(".exam_schedule_intro", group: exam_group_label)
          end

          div(class: "grid grid-cols-1 sm:grid-cols-2 gap-4") do
            render_season_slot(apr_jul_season) if apr_jul_season
            render_season_slot(oct_jan_season) if oct_jan_season
          end
        end
      end

      def render_season_slot(season)
        slot = ExamTimetable.slot_for(group: @course.exam_group, season: season)
        return unless slot

        div(class: "bg-gray-50 rounded-lg p-4") do
          p(class: "text-xs font-medium text-gray-500 uppercase tracking-wide") { season.label }
          p(class: "text-base font-semibold text-gray-900 mt-1") do
            "#{slot.day_label} #{slot.time}"
          end
          p(class: "text-xs text-gray-500 mt-1") do
            l(slot.day == "saturday" ? season.exam_start : season.exam_end, format: :full)
          end
        end
      end

      def render_references
        div(class: "bg-white rounded-lg shadow p-6 mb-6") do
          h2(class: "text-lg font-semibold text-gray-900 mb-4") { t("shared.references.title") }

          div(class: "space-y-3") do
            if @course.syllabus_page
              link_to(
                documents_path(pdf: "syllabus", page: @course.syllabus_page),
                class: "flex items-center gap-3 p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition"
              ) do
                span(class: "text-lg") { "📄" }
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
                span(class: "text-lg") { "📝" }
                div do
                  p(class: "text-sm font-medium text-gray-900") { t("shared.references.report_guide") }
                  p(class: "text-xs text-gray-500") { t("shared.page", page: @course.report_page) }
                end
              end
            end
          end
        end
      end

      def render_add_to_plan_section
        if @existing_enrollment
          render_already_enrolled
        else
          render_add_form
        end
      end

      def render_already_enrolled
        div(class: "bg-green-50 border border-green-200 rounded-lg p-6") do
          h2(class: "text-lg font-semibold text-green-900 mb-2") { t(".already_title") }
          p(class: "text-sm text-green-800 mb-4") do
            t(".already_text", season: @existing_enrollment.season&.name || t(".a_season"))
          end
          link_to(
            t(".view_in_planner"),
            enrollment_path(@existing_enrollment),
            class: "inline-flex items-center px-4 py-2 border border-green-600 rounded-md text-sm font-medium text-green-700 hover:bg-green-100"
          )
        end
      end

      def render_add_form
        div(class: "bg-white rounded-lg shadow p-6") do
          h2(class: "text-lg font-semibold text-gray-900 mb-4") { t(".add_to_plan") }

          form_with(url: enrollments_path, scope: :enrollment, method: :post, class: "space-y-5") do |f|
            f.hidden_field(:course_key, value: @course.key)
            f.hidden_field(:status, value: "planned")

            div do
              label(class: "block text-sm font-medium text-gray-700 mb-2") { t(".target_season") }
              render_season_picker
            end

            div(class: "flex gap-3 pt-2") do
              f.submit(
                t(".add_to_plan"),
                class: "flex-1 inline-flex justify-center py-2 px-4 rounded-md text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 cursor-pointer"
              )
              link_to(
                t("shared.cancel"),
                catalog_path,
                class: "flex-1 inline-flex justify-center py-2 px-4 border border-gray-300 rounded-md text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
              )
            end
          end
        end
      end

      def render_season_picker
        div(class: "grid grid-cols-1 sm:grid-cols-2 gap-3") do
          @seasons.each_with_index do |season, i|
            render_season_card(season, checked: i == 0)
          end
        end
      end

      def render_season_card(season, checked:)
        id = "season_#{season.key}"

        label(
          for: id,
          class: [
            "relative flex flex-col gap-2 p-4 rounded-lg border-2 cursor-pointer transition",
            "border-gray-200 hover:border-indigo-300",
            "has-[:checked]:border-indigo-600 has-[:checked]:bg-indigo-50 has-[:checked]:ring-2 has-[:checked]:ring-indigo-100"
          ].join(" ")
        ) do
          input(
            type: "radio",
            name: "enrollment[season_key]",
            id: id,
            value: season.key,
            checked: checked,
            class: "sr-only",
            required: true
          )

          # Header: name + checkmark on select
          div(class: "flex items-center justify-between") do
            span(class: "font-semibold text-gray-900") { season.label }
            span(class: "text-indigo-600 hidden peer-checked:inline", aria_hidden: true) { "✓" }
          end

          # Exam dates
          div(class: "text-xs text-gray-500") do
            plain t(".exam_dates", dates: t("shared.date_range", from: l(season.exam_start, format: :month_day), to: l(season.exam_end, format: :month_day)))
          end

          # Deadline badge
          render_deadline_hint(season)
        end
      end

      def render_deadline_hint(season)
        days = season.days_until_report_deadline
        return if days < 0

        color = case days
        when 0..3 then "bg-red-100 text-red-700"
        when 4..14 then "bg-amber-100 text-amber-700"
        else "bg-gray-100 text-gray-600"
        end

        div(class: "flex items-center gap-1.5 text-xs") do
          span(class: "text-gray-500") { t(".report_due") }
          span(class: "font-medium text-gray-700") { l(season.report_deadline, format: :month_day) }
          span(class: "px-1.5 py-0.5 rounded #{color}") do
            days == 0 ? t("shared.today") : t(".days_left_short", count: days)
          end
        end
      end

      def tag(text, color_class)
        span(class: "px-3 py-1 rounded-full text-sm font-medium #{color_class}") { text }
      end

      def field_color(field)
        {
          "humanities" => "bg-red-50 text-red-700",
          "social" => "bg-purple-50 text-purple-700",
          "natural" => "bg-teal-50 text-teal-700",
          "foreign_language" => "bg-green-50 text-green-700",
          "economics" => "bg-orange-50 text-orange-700"
        }[field] || "bg-gray-50 text-gray-700"
      end
    end
  end
end
