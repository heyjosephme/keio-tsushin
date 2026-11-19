# frozen_string_literal: true

module Views
  module Enrollments
    class Index < Views::Base
      include Phlex::Rails::Helpers::Flash
      include Phlex::Rails::Helpers::LinkTo
      include Phlex::Rails::Helpers::FormWith

      def initialize(seasons:, enrollments_by_season:, courses:, undecided_courses: [])
        @seasons = seasons
        @enrollments_by_season = enrollments_by_season
        @courses = courses
        @undecided_courses = undecided_courses
      end

      def view_template
        render Components::Layout.new do
          div(class: "py-8") do
            div(class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8") do
              render_flash_messages
              render_header

              div(class: "mb-6") { render Components::NextDeadlines.new }

              render_undecided_courses if @undecided_courses.any?

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
          h1(class: "text-3xl font-bold text-gray-900") { t(".title") }
          link_to(
            t(".browse"),
            catalog_path,
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

      # Compulsory courses the user hasn't scheduled yet. Picking a season adds the
      # course to the plan; removing it from the plan brings it back here.
      def render_undecided_courses
        div(class: "mb-6 rounded-lg border-2 border-dashed border-gray-300 bg-white p-4") do
          h2(class: "font-semibold text-gray-900") { t(".undecided_title") }
          p(class: "mt-1 text-xs text-gray-500") { t(".undecided_hint") }

          div(class: "mt-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3") do
            @undecided_courses.each { |course| render_undecided_card(course) }
          end
        end
      end

      def render_undecided_card(course)
        div(class: "bg-gray-50 rounded-lg p-3 border border-gray-200") do
          link_to(catalog_course_path(course.key), class: "block") do
            p(class: "font-medium text-gray-900 text-sm hover:text-indigo-600") { course.localized_name }
            p(class: "text-xs text-gray-500") { course.secondary_name } if course.secondary_name
            p(class: "text-xs text-gray-500 mt-1") do
              span(class: "px-1.5 py-0.5 rounded text-xs bg-red-50 text-red-700") { t(".required") }
              span(class: "ml-2") { t("shared.credits", count: course.credits) } if course.credits
            end
          end

          form_with(url: enrollments_path, scope: :enrollment, class: "mt-3") do |f|
            f.hidden_field(:course_key, value: course.key, id: nil)
            f.hidden_field(:status, value: "planned", id: nil)
            f.select(
              :season_key,
              @seasons.map { |s| [ s.short_name, s.key ] },
              { prompt: t(".choose_season") },
              id: nil,
              aria: { label: t(".choose_season") },
              class: "w-full text-xs border-gray-300 rounded py-1 pr-8",
              onchange: "this.form.submit()"
            )
          end
        end
      end

      def render_season_column(season)
        enrollments = @enrollments_by_season[season.key] || []

        div(class: "bg-white rounded-lg shadow") do
          # Season header
          div(class: "p-4 border-b border-gray-200") do
            h2(class: "font-semibold text-gray-900") do
              plain season.short_name
              span(class: "ml-2 px-1.5 py-0.5 rounded text-xs font-normal bg-amber-100 text-amber-800") { t("shared.estimated") } if season.estimated?
            end
            render_season_dates(season)
          end

          # Enrollments list
          div(class: "p-4 space-y-3 min-h-[200px]") do
            if enrollments.any?
              enrollments.each { |enrollment| render_enrollment_card(enrollment) }
            else
              p(class: "text-gray-400 text-sm text-center py-8") { t(".no_courses") }
            end

            # Add course to this season
            link_to(
              t(".add"),
              catalog_path,
              class: "block text-center text-sm text-indigo-600 hover:text-indigo-800 py-2"
            )
          end

          # Exam schedule preview
          render_exam_schedule(season, enrollments) if enrollments.any?
        end
      end

      def render_season_dates(season)
        div(class: "mt-2 text-xs text-gray-500 space-y-1") do
          div do
            span(class: "font-medium") { t(".report") }
            span { l(season.report_deadline, format: :month_day) }
            render_days_badge(season.days_until_report_deadline)
          end
          div do
            span(class: "font-medium") { t(".apply") }
            span { l(season.application_deadline, format: :month_day) }
          end
          div do
            span(class: "font-medium") { t(".exam") }
            span { t("shared.date_range", from: l(season.exam_start, format: :month_day), to: l(season.exam_end, format: :month_day)) }
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
          days == 0 ? t("shared.today") : t(".days_short", count: days)
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
                p(class: "font-medium text-gray-900 text-sm hover:text-indigo-600") { enrollment.localized_name }
                p(class: "text-xs text-gray-500") { enrollment.secondary_name } if enrollment.secondary_name
                p(class: "text-xs text-gray-500 mt-1") do
                  render_status_badge(enrollment.status)
                  span(class: "ml-2") { t("shared.credits", count: enrollment.credits) } if enrollment.credits
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
              t(".syllabus_link", page: course.syllabus_page),
              documents_path(pdf: "syllabus", page: course.syllabus_page),
              class: "text-indigo-600 hover:text-indigo-800"
            )
          end

          if course.report_page
            link_to(
              t(".report_link", page: course.report_page),
              documents_path(pdf: course.report_pdf, page: course.report_page),
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
          t("shared.statuses.#{status}")
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
            data: { turbo_confirm: t(".remove_confirm") }
          ) { t(".remove") }
        end
      end

      def render_exam_schedule(season, enrollments)
        schedule = ExamTimetable.schedule_for(enrollments: enrollments, season: season)
        conflicts = ExamTimetable.conflicts_for(enrollments: enrollments)

        # Only show if at least one course has an exam group assigned
        return if schedule.empty? && conflicts.empty?

        div(class: "px-4 pb-4 border-t border-gray-200") do
          h3(class: "text-xs font-semibold text-gray-500 uppercase tracking-wide pt-3 pb-2") { t(".exam_schedule") }

          # Conflict warnings
          render_exam_conflicts(conflicts, season) if conflicts.any?

          # Schedule table
          if schedule.any?
            div(class: "space-y-1.5") do
              current_day = nil

              schedule.each do |entry|
                slot = entry[:slot]

                # Day separator
                if slot.day != current_day
                  current_day = slot.day
                  div(class: "flex items-center gap-1.5 mt-2 first:mt-0") do
                    span(class: "text-xs font-medium text-gray-700") do
                      slot.day_label
                    end
                    span(class: "text-xs text-gray-400") do
                      slot.day == "saturday" ? season.exam_start.strftime("%-m/%-d") : season.exam_end.strftime("%-m/%-d")
                    end
                  end
                end

                # Time slot with courses
                div(class: "flex items-start gap-2 pl-2") do
                  span(class: "text-xs text-gray-500 whitespace-nowrap w-20 shrink-0") { slot.time }
                  div(class: "text-xs") do
                    entry[:courses].each_with_index do |course, i|
                      span(class: "text-gray-400") { ", " } if i > 0
                      span(class: "text-gray-800") { course.localized_name }
                      span(class: "text-gray-400 ml-0.5") { "(#{t('shared.exam_group', group: slot.group)})" }
                    end
                  end
                end
              end
            end
          end
        end
      end

      def render_exam_conflicts(conflicts, season)
        conflicts.each do |group, group_enrollments|
          slot = ExamTimetable.slot_for(group: group, season: season)
          course_names = group_enrollments.map { |e| e.course&.localized_name }.compact.to_sentence

          div(class: "mb-2 rounded-md bg-amber-50 border border-amber-200 p-2") do
            p(class: "text-xs text-amber-800") do
              strong { t(".conflict_label") }
              plain t(".conflict", courses: course_names, group: t("shared.exam_group", group: group))
              if slot
                plain " (#{slot.day_label} #{slot.time})"
              end
            end
          end
        end
      end
    end
  end
end
