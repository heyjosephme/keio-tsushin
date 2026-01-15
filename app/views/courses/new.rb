# frozen_string_literal: true

module Views
  module Courses
    class New < Views::Base
      include Phlex::Rails::Helpers::FormWith
      include Phlex::Rails::Helpers::LinkTo

      def initialize(course:, seasons:)
        @course = course
        @seasons = seasons
      end

      def view_template
        div(class: "min-h-screen bg-gray-50 py-8") do
          div(class: "max-w-2xl mx-auto px-4 sm:px-6 lg:px-8") do
            # Header
            div(class: "mb-8") do
              div(class: "mb-4") do
                link_to(
                  "← Back to Courses",
                  courses_path,
                  class: "text-indigo-600 hover:text-indigo-800 text-sm font-medium"
                )
              end
              h1(class: "text-3xl font-bold text-gray-900") { "Add Course" }
            end

            # Form
            div(class: "bg-white shadow rounded-lg p-6") do
              form_with(model: @course, url: courses_path, class: "space-y-6") do |f|
                # Course Name
                div do
                  label(for: "course_name", class: "block text-sm font-medium text-gray-700") do
                    "Course Name"
                  end
                  f.text_field(
                    :name,
                    class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm",
                    placeholder: "e.g., Philosophy of Science"
                  )
                  render_errors(:name)
                end

                # Season
                div do
                  label(for: "course_season_key", class: "block text-sm font-medium text-gray-700") do
                    "Target Season"
                  end
                  f.select(
                    :season_key,
                    @seasons.map { |s| [ s.name, s.key ] },
                    { prompt: "Select season" },
                    class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                  )
                  render_errors(:season_key)
                end

                # Credits
                div do
                  label(for: "course_credits", class: "block text-sm font-medium text-gray-700") do
                    "Credits (optional)"
                  end
                  f.number_field(
                    :credits,
                    class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm",
                    min: 1,
                    max: 8,
                    placeholder: "e.g., 2"
                  )
                end

                # Submit
                div(class: "flex gap-4") do
                  f.submit(
                    "Add Course",
                    class: "flex-1 inline-flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700"
                  )

                  link_to(
                    "Cancel",
                    courses_path,
                    class: "flex-1 inline-flex justify-center py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
                  )
                end
              end
            end
          end
        end
      end

      private

      def render_errors(field)
        return unless @course.errors[field].any?

        p(class: "mt-2 text-sm text-red-600") { @course.errors[field].join(", ") }
      end
    end
  end
end
