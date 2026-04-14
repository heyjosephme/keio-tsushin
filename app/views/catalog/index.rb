# frozen_string_literal: true

module Views
  module Catalog
    class Index < Views::Base
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
              render_header
              render_filters
              render_course_grid
            end
          end
        end
      end

      private

      def render_header
        div(class: "mb-6") do
          h1(class: "text-3xl font-bold text-gray-900") { "Course Catalog" }
          p(class: "text-sm text-gray-500 mt-1") do
            "Browse all courses available for your major. Click a course for details and to add it to your plan."
          end
        end
      end

      def render_filters
        div(class: "mb-6 bg-white rounded-lg shadow-sm p-4 space-y-4") do
          # Field tabs
          div(class: "flex flex-wrap gap-2") do
            field_tab("All", nil)
            field_tab("人文科学", "humanities")
            field_tab("社会科学", "social")
            field_tab("自然科学", "natural")
            field_tab("外国語", "foreign_language")
            field_tab("経済学", "economics")
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
              plain "Hide courses already in my plan"
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
            p(class: "text-gray-500") { "No courses match your filters." }
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
              h3(class: "font-semibold text-gray-900") { course.name }
              p(class: "text-sm text-gray-500") { course.name_ja } if course.name_ja
            end
            if enrolled
              span(class: "px-2 py-0.5 text-xs font-medium rounded-full bg-green-100 text-green-700 whitespace-nowrap") do
                "In plan"
              end
            end
          end

          div(class: "mt-3 flex flex-wrap gap-1.5") do
            badge("#{course.credits}単位", "bg-gray-100 text-gray-700")
            badge(course.field_label, field_color(course.field))
            badge("#{course.exam_group}群", "bg-indigo-50 text-indigo-700") if course.exam_group
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
