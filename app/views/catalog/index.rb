# frozen_string_literal: true

module Views
  module Catalog
    class Index < Views::Base
      include Phlex::Rails::Helpers::Flash
      include Phlex::Rails::Helpers::LinkTo

      def initialize(courses:, field:, exclude_enrolled:, enrolled_keys:)
        @courses = courses
        @field = field
        @exclude_enrolled = exclude_enrolled
        @enrolled_keys = enrolled_keys
      end

      def view_template
        render Components::Layout.new do
          div(class: "py-8") do
            div(class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8") do
              render_flash_messages
              render_header
              render_filters
              render_course_grid
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

      def render_header
        div(class: "mb-6") do
          h1(class: "text-3xl font-bold text-gray-900") { t(".title") }
          p(class: "text-sm text-gray-500 mt-1") do
            t(".intro")
          end
        end
      end

      def render_filters
        div(class: "mb-6 bg-white rounded-lg shadow-sm p-4 space-y-4") do
          # Field tabs
          div(class: "flex flex-wrap gap-2") do
            field_tab(t("shared.all"), nil)
            Course::FIELDS.each { |field| field_tab(t("shared.fields.#{field}"), field) }
          end

          # Exclude-enrolled toggle
          div(class: "flex items-center gap-2 text-sm") do
            link_to(
              catalog_path(field: @field, exclude_enrolled: @exclude_enrolled ? nil : "1"),
              class: "inline-flex items-center gap-2 text-gray-700 hover:text-indigo-600"
            ) do
              span(class: "inline-flex items-center justify-center w-4 h-4 rounded border border-gray-300 #{@exclude_enrolled ? 'bg-indigo-600 border-indigo-600' : 'bg-white'}") do
                span(class: "text-white text-xs") { "✓" } if @exclude_enrolled
              end
              plain t(".hide_enrolled")
            end
          end
        end
      end

      def field_tab(label, field)
        active = @field == field
        classes = [
          "px-3 py-1.5 text-sm font-medium rounded-full border transition-colors",
          active ? "bg-indigo-600 text-white border-indigo-600" : "bg-white text-gray-600 border-gray-300 hover:bg-gray-50"
        ].join(" ")

        link_to(
          label,
          catalog_path(field: field, exclude_enrolled: @exclude_enrolled ? "1" : nil),
          class: classes
        )
      end

      def render_course_grid
        if @courses.empty?
          div(class: "bg-white rounded-lg shadow-sm p-12 text-center") do
            p(class: "text-gray-500") { t(".no_match") }
          end
        else
          div(class: "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4") do
            @courses.each { |course| render_course_card(course) }
          end
        end
      end

      def render_course_card(course)
        enrolled = @enrolled_keys.include?(course.key)

        link_to(
          catalog_course_path(course.key),
          class: "block bg-white rounded-lg shadow-sm border border-gray-200 p-4 hover:border-indigo-300 hover:shadow-md transition"
        ) do
          div(class: "flex justify-between items-start mb-2") do
            div do
              h3(class: "font-semibold text-gray-900") { course.localized_name }
              p(class: "text-sm text-gray-500") { course.secondary_name } if course.secondary_name
            end
            if enrolled
              span(class: "px-2 py-0.5 text-xs font-medium rounded-full bg-green-100 text-green-700 whitespace-nowrap") do
                t(".in_plan")
              end
            end
          end

          div(class: "mt-3 flex flex-wrap gap-1.5") do
            badge(t("shared.credits", count: course.credits), "bg-gray-100 text-gray-700")
            badge(course.field_label, field_color(course.field))
            badge(t("shared.exam_group", group: course.exam_group), "bg-indigo-50 text-indigo-700") if course.exam_group
          end
        end
      end

      def badge(text, classes)
        span(class: "inline-block px-2 py-0.5 rounded text-xs font-medium #{classes}") { text }
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
