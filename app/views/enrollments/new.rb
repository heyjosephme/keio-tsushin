# frozen_string_literal: true

module Views
  module Enrollments
    class New < Views::Base
      include Phlex::Rails::Helpers::FormWith
      include Phlex::Rails::Helpers::LinkTo

      def initialize(enrollment:, seasons:, courses:)
        @enrollment = enrollment
        @seasons = seasons
        @courses = courses
      end

      def view_template
        div(class: "min-h-screen bg-gray-50 py-8") do
          div(class: "max-w-4xl mx-auto px-4 sm:px-6 lg:px-8") do
            render_header
            render_form
          end
        end
      end

      private

      def render_header
        div(class: "mb-8") do
          div(class: "mb-4") do
            link_to(
              t(".back"),
              enrollments_path,
              class: "text-primary-700 hover:text-primary-900 text-sm font-medium"
            )
          end
          h1(class: "text-3xl font-bold text-gray-900") { t(".title") }
        end
      end

      def render_form
        div(class: "bg-white shadow rounded-lg p-6") do
          form_with(model: @enrollment, url: enrollments_path, class: "space-y-6") do |f|
            render_course_selector(f)
            render_season_select(f)
            render_submit_buttons(f)
          end
        end
      end

      def render_course_selector(form)
        div(data: { controller: "course-selector" }) do
          label(class: "block text-sm font-medium text-gray-700 mb-2") do
            t(".select_course")
          end

          # Hidden input for form submission
          form.hidden_field(:course_key, data: { course_selector_target: "input" })

          # Selected course display
          div(class: "mb-4") do
            span(class: "text-sm text-gray-500") { t(".selected") }
            span(
              class: "text-sm font-medium text-primary-700 hidden",
              data: { course_selector_target: "selectedDisplay" }
            ) { "" }
          end

          # Search input
          div(class: "mb-4") do
            input(
              type: "text",
              placeholder: t(".search_placeholder"),
              class: "w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 text-sm py-3 px-4",
              data: {
                course_selector_target: "search",
                action: "input->course-selector#search"
              }
            )
          end

          # Field tabs
          render_field_tabs

          # Course cards grid
          render_course_cards

          render_errors(:course_key)
        end
      end

      def render_field_tabs
        div(class: "flex flex-wrap gap-2 mb-4") do
          tab(t("shared.all"), "all", selected: true)
          Course::FIELDS.each { |field| tab(t("shared.fields.#{field}"), field) }
        end
      end

      def tab(label, field, selected: false)
        base_classes = "px-3 py-1.5 text-sm font-medium rounded-full cursor-pointer transition-colors border"
        active_classes = selected ? "bg-primary-800 text-white border-primary-600" : "bg-white text-gray-600 border-gray-300 hover:bg-gray-50"

        button(
          type: "button",
          class: "#{base_classes} #{active_classes}",
          data: {
            course_selector_target: "tab",
            field: field,
            action: "click->course-selector#selectField"
          }
        ) { label }
      end

      def render_course_cards
        div(class: "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 max-h-96 overflow-y-auto p-1") do
          @courses.each do |course|
            render_course_card(course)
          end
        end
      end

      def render_course_card(course)
        div(
          class: "bg-white border border-gray-200 rounded-lg p-3 cursor-pointer hover:border-primary-300 hover:shadow-sm transition-all",
          data: {
            course_selector_target: "card",
            course_key: course.key,
            course_name: course.localized_name,
            name: course.name,
            name_ja: course.name_ja,
            field: course.field,
            action: "click->course-selector#selectCourse"
          }
        ) do
          # Course name
          div(class: "font-medium text-gray-900 text-sm") { course.localized_name }
          div(class: "text-gray-500 text-xs") { course.secondary_name }

          # Credits and field badges
          div(class: "mt-2 flex items-center gap-2") do
            span(class: "inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-700") do
              t("shared.credits", count: course.credits)
            end
            render Components::FieldTag.new(course)
          end
        end
      end

      def render_season_select(form)
        div do
          label(for: "enrollment_season_key", class: "block text-sm font-medium text-gray-700") do
            t(".target_season")
          end
          form.select(
            :season_key,
            @seasons.map { |s| [ s.label, s.key ] },
            { prompt: t(".season_prompt") },
            class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 sm:text-sm"
          )
          render_errors(:season_key)
        end
      end

      def render_submit_buttons(form)
        div(class: "flex gap-4") do
          form.submit(
            t(".submit"),
            class: "flex-1 inline-flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-primary-800 hover:bg-primary-700 cursor-pointer"
          )

          link_to(
            t("shared.cancel"),
            enrollments_path,
            class: "flex-1 inline-flex justify-center py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
          )
        end
      end

      def render_errors(field)
        return unless @enrollment.errors[field].any?

        p(class: "mt-2 text-sm text-danger-600") { @enrollment.errors.full_messages_for(field).to_sentence }
      end
    end
  end
end
