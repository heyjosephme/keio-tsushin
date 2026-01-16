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
          div(class: "max-w-2xl mx-auto px-4 sm:px-6 lg:px-8") do
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
              "← Back to Courses",
              enrollments_path,
              class: "text-indigo-600 hover:text-indigo-800 text-sm font-medium"
            )
          end
          h1(class: "text-3xl font-bold text-gray-900") { "Add Course to Plan" }
        end
      end

      def render_form
        div(class: "bg-white shadow rounded-lg p-6") do
          form_with(model: @enrollment, url: enrollments_path, class: "space-y-6") do |f|
            # Course Selection (grouped by category)
            div do
              label(for: "enrollment_course_key", class: "block text-sm font-medium text-gray-700") do
                "Select Course"
              end
              f.select(
                :course_key,
                grouped_courses_for_select,
                { prompt: "Choose a course..." },
                class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              )
              render_errors(:course_key)
            end

            # Season Selection
            div do
              label(for: "enrollment_season_key", class: "block text-sm font-medium text-gray-700") do
                "Target Season"
              end
              f.select(
                :season_key,
                @seasons.map { |s| [ s.name, s.key ] },
                { prompt: "Select season..." },
                class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              )
              render_errors(:season_key)
            end

            # Submit Buttons
            div(class: "flex gap-4") do
              f.submit(
                "Add to Plan",
                class: "flex-1 inline-flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700"
              )

              link_to(
                "Cancel",
                enrollments_path,
                class: "flex-1 inline-flex justify-center py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
              )
            end
          end
        end
      end

      def grouped_courses_for_select
        {
          "必修科目 (Required)" => @courses.select(&:required?).map { |c| [ "#{c.name} (#{c.credits}単位)", c.key ] },
          "選択科目 (Elective)" => @courses.select { |c| c.category == "elective" }.map { |c| [ "#{c.name} (#{c.credits}単位)", c.key ] },
          "外国語 (Foreign Language)" => @courses.select { |c| c.category == "foreign_language" }.map { |c| [ "#{c.name} (#{c.credits}単位)", c.key ] }
        }.reject { |_, v| v.empty? }
      end

      def render_errors(field)
        return unless @enrollment.errors[field].any?

        p(class: "mt-2 text-sm text-red-600") { @enrollment.errors[field].join(", ") }
      end
    end
  end
end
