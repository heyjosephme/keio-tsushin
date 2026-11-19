# frozen_string_literal: true

module Views
  module Enrollments
    class Index < Views::Base
      include Phlex::Rails::Helpers::Flash
      include Phlex::Rails::Helpers::LinkTo
      include Phlex::Rails::Helpers::FormWith

      def initialize(seasons:, enrollments_by_season:, courses:, undecided_courses: [], past_seasons: [], major_set: true)
        @seasons = seasons
        @enrollments_by_season = enrollments_by_season
        @courses = courses
        @undecided_courses = undecided_courses
        @past_seasons = past_seasons
        @major_set = major_set
      end

      FIELD_STRIPES = Components::FieldTag::STRIPES

      SELECT_CLASS = "text-xs text-gray-700 bg-white border border-gray-300 rounded-md py-1 pl-2 pr-7 focus:border-primary-500 focus:ring-1 focus:ring-primary-500"

      def view_template
        render Components::Layout.new do
          div(class: "py-8") do
            div(class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8") do
              render_flash_messages
              render_header

              div(class: "mb-6") { render Components::NextDeadlines.new }

              render_major_hint unless @major_set
              render_undecided_courses if @undecided_courses.any?

              # Kanban board
              div(class: "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 items-start") do
                @seasons.each_with_index do |season, index|
                  render_season_column(season, current: index.zero?)
                end
              end

              render_past_seasons if @past_seasons.any?
            end
          end
        end
      end

      private

      def icon(name, **)
        render Components::Icon.new(name, **)
      end

      def render_header
        div(class: "mb-8 flex justify-between items-center") do
          h1(class: "text-3xl font-bold tracking-tight text-primary-900") { t(".title") }
          link_to(
            catalog_path,
            class: "inline-flex items-center gap-2 px-4 py-2 rounded-md shadow-sm text-sm font-medium text-white bg-primary-800 hover:bg-primary-700"
          ) do
            icon(:search)
            plain t(".browse")
          end
        end
      end

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

      # Compulsory courses the user hasn't scheduled yet. Picking a season adds the
      # course to the plan; removing it from the plan brings it back here.
      def render_undecided_courses
        div(class: "mb-6 rounded-xl border-2 border-dashed border-primary-200 bg-white/70 p-4") do
          h2(class: "flex items-center gap-2 font-semibold text-primary-900") do
            icon(:clock, class: "size-5 shrink-0 text-primary-500")
            plain t(".undecided_title")
          end
          p(class: "mt-1 text-xs text-gray-500") { t(".undecided_hint") }

          div(class: "mt-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3") do
            @undecided_courses.each { |course| render_undecided_card(course) }
          end
        end
      end

      # Required courses depend on the major, so without one the undecided box stays empty
      def render_major_hint
        div(class: "mb-6 rounded-xl border-2 border-dashed border-primary-200 bg-white/70 p-4 flex flex-wrap items-center justify-between gap-3") do
          p(class: "text-sm text-gray-600") { t(".major_hint") }
          link_to(t(".set_major"), edit_profile_path, class: "text-sm font-medium text-primary-700 hover:text-primary-900")
        end
      end

      # Seasons whose exams are over, collapsed below the board
      def render_past_seasons
        details(class: "mt-8") do
          summary(class: "cursor-pointer inline-flex items-center gap-2 text-sm font-semibold text-primary-800") do
            icon(:archive)
            plain t(".past_seasons", count: @past_seasons.size)
          end

          div(class: "mt-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 items-start") do
            @past_seasons.each { |season| render_season_column(season, past: true) }
          end
        end
      end

      def render_undecided_card(course)
        div(class: "bg-white rounded-lg p-3 ring-1 ring-gray-200 border-l-4 #{FIELD_STRIPES[course.field]}") do
          link_to(catalog_course_path(course.key), class: "block group") do
            p(class: "font-medium text-primary-950 text-sm group-hover:text-primary-600") { course.localized_name }
            p(class: "text-xs text-gray-500") { course.secondary_name } if course.secondary_name
            p(class: "text-xs text-gray-500 mt-2 flex items-center gap-2") do
              span(class: "px-1.5 py-0.5 rounded bg-danger-50 text-danger-700") { t(".required") }
              span { t("shared.credits", count: course.credits) } if course.credits
            end
          end

          form_with(url: enrollments_path, scope: :enrollment, class: "mt-3") do |f|
            f.hidden_field(:course_key, value: course.key, id: nil)
            f.hidden_field(:status, value: "planned", id: nil)
            f.select(
              :season_key,
              @seasons.map { |s| [ s.label, s.key ] },
              { prompt: t(".choose_season") },
              id: nil,
              aria: { label: t(".choose_season") },
              class: "w-full #{SELECT_CLASS}",
              onchange: "this.form.submit()"
            )
          end
        end
      end

      # current: the season in progress, marked with the accent colour
      def render_season_column(season, past: false, current: false)
        enrollments = @enrollments_by_season[season.key] || []
        top = current ? "border-accent-400" : (past ? "border-gray-300" : "border-primary-800")

        div(class: "#{past ? "bg-white/60" : "bg-white"} rounded-xl shadow-sm ring-1 ring-primary-100 border-t-4 #{top}") do
          # Season header
          div(class: "p-4 border-b border-gray-100") do
            h2(class: "text-lg font-bold tracking-tight text-primary-900") do
              plain season.short_name
              if season.estimated?
                span(class: "ml-2 align-middle px-1.5 py-0.5 rounded text-xs font-normal border border-dashed border-gray-400 text-gray-600") { t("shared.estimated") }
              end
            end
            render_season_dates(season)
          end

          # Enrollments list
          div(class: "p-3 space-y-3 min-h-[160px]") do
            if enrollments.any?
              enrollments.each { |enrollment| render_enrollment_card(enrollment) }
            else
              p(class: "text-gray-400 text-sm text-center py-8") { t(".no_courses") }
            end

            # Add course to this season
            unless past
              link_to(
                catalog_path,
                class: "flex items-center justify-center gap-1 rounded-lg border border-dashed border-primary-200 text-sm text-primary-700 hover:bg-primary-50 hover:border-primary-400 py-2"
              ) do
                icon(:plus)
                plain t(".add")
              end
            end
          end

          # Exam schedule preview
          render_exam_schedule(season, enrollments) if enrollments.any?
        end
      end

      # One icon per date instead of a text label; the label stays as a tooltip
      # and for screen readers. Dates that have passed are struck through.
      def render_season_dates(season)
        div(class: "mt-3 text-xs space-y-1.5") do
          render_season_date(:report, t(".report"), season.report_deadline) do
            plain l(season.report_deadline, format: :month_day)
            render_days_badge(season.days_until_report_deadline)
          end
          render_season_date(:apply, t(".apply"), season.application_deadline) do
            plain l(season.application_deadline, format: :month_day)
            render_days_badge(season.days_until_application_deadline)
          end
          render_season_date(:calendar, t(".exam"), season.exam_end) do
            plain t("shared.date_range", from: l(season.exam_start, format: :month_day), to: l(season.exam_end, format: :month_day))
          end
        end
      end

      def render_season_date(icon_name, label, date, &)
        passed = date < Date.today

        div(class: "flex items-center gap-2 #{passed ? "text-gray-400" : "text-gray-700"}", title: label) do
          icon(icon_name, class: "size-3.5 shrink-0 #{passed ? "text-gray-300" : "text-primary-500"}")
          span(class: "sr-only") { label }
          span(class: passed ? "line-through" : nil, &)
        end
      end

      def render_days_badge(days)
        return if days < 0 || days > 30

        color = case days
        when 0..3 then "bg-danger-100 text-danger-700"
        when 4..7 then "bg-warning-100 text-warning-700"
        else "bg-gray-100 text-gray-600"
        end

        span(class: "ml-2 px-1.5 py-0.5 rounded text-xs #{color}") do
          days == 0 ? t("shared.today") : t(".days_short", count: days)
        end
      end

      def render_enrollment_card(enrollment)
        course = enrollment.course

        div(class: "group/card bg-white rounded-lg p-3 ring-1 ring-gray-200 border-l-4 #{FIELD_STRIPES[course&.field] || "border-l-gray-300"} hover:ring-primary-300 transition") do
          link_to(enrollment_path(enrollment), class: "block") do
            p(class: "font-medium text-primary-950 text-sm group-hover/card:text-primary-600") { enrollment.localized_name }
            p(class: "text-xs text-gray-500") { enrollment.secondary_name } if enrollment.secondary_name
            p(class: "text-xs text-gray-500 mt-2 flex items-center gap-2") do
              render_status_badge(enrollment.status)
              span { t("shared.credits", count: enrollment.credits) } if enrollment.credits
            end
          end

          # Reference links
          render_reference_links(course) if course&.has_references?

          # Move to another season, or remove
          div(class: "mt-3 flex items-center justify-between gap-2") do
            render_move_dropdown(enrollment)
            render_delete_button(enrollment)
          end
        end
      end

      def render_reference_links(course)
        div(class: "mt-2 flex gap-3 text-xs") do
          if course.syllabus_page
            render_reference_link(:book, t(".syllabus_link", page: course.syllabus_page), course.syllabus_page,
              documents_path(pdf: "syllabus", page: course.syllabus_page))
          end

          if course.report_page
            render_reference_link(:report, t(".report_link", page: course.report_page), course.report_page,
              documents_path(pdf: course.report_pdf, page: course.report_page))
          end
        end
      end

      def render_reference_link(icon_name, label, page, path)
        link_to(path, title: label, aria: { label: label }, class: "inline-flex items-center gap-1 text-primary-600 hover:text-primary-900") do
          icon(icon_name, class: "size-3.5 shrink-0")
          plain t(".page_short", page: page)
        end
      end

      def render_status_badge(status)
        render Components::StatusBadge.new(status)
      end

      # A course in a past season isn't in the list, so it gets a "Move to…" prompt instead
      def render_move_dropdown(enrollment)
        in_list = @seasons.any? { |s| s.key == enrollment.season_key }

        form_with(model: enrollment, method: :patch, class: "min-w-0") do |f|
          f.select(
            :season_key,
            @seasons.map { |s| [ s.label, s.key ] },
            in_list ? { selected: enrollment.season_key } : { include_blank: t(".move_to"), selected: "" },
            id: nil,
            aria: { label: t(".move_to") },
            class: "max-w-full #{SELECT_CLASS}",
            onchange: "this.form.submit()"
          )
        end
      end

      def render_delete_button(enrollment)
        form_with(url: enrollment_path(enrollment), method: :delete, class: "inline-flex") do
          button(
            type: "submit",
            title: t(".remove"),
            class: "p-1 rounded text-gray-400 hover:text-danger-600 hover:bg-danger-50 cursor-pointer",
            data: { turbo_confirm: t(".remove_confirm") }
          ) { icon(:trash, label: t(".remove")) }
        end
      end

      def render_exam_schedule(season, enrollments)
        schedule = ExamTimetable.schedule_for(enrollments: enrollments, season: season)
        conflicts = ExamTimetable.conflicts_for(enrollments: enrollments)

        # Only show if at least one course has an exam group assigned
        return if schedule.empty? && conflicts.empty?

        div(class: "px-4 pb-4 border-t border-gray-100 bg-primary-50/40 rounded-b-xl") do
          h3(class: "flex items-center gap-1.5 text-xs font-semibold text-primary-800 uppercase tracking-wide pt-3 pb-2") do
            icon(:calendar, class: "size-3.5 shrink-0")
            plain t(".exam_schedule")
          end

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

          div(class: "mb-2 flex gap-2 rounded-md bg-warning-50 border border-warning-200 p-2") do
            icon(:warning, class: "size-4 shrink-0 text-warning-600 mt-0.5")
            p(class: "text-xs text-warning-800") do
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
