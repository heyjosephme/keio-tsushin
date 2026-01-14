# frozen_string_literal: true

module Views
  module Deadlines
    class New < Views::Base
      include Phlex::Rails::Helpers::FormWith
      include Phlex::Rails::Helpers::LinkTo

      def initialize(deadline:)
        @deadline = deadline
      end

      def view_template
        div(class: "min-h-screen bg-gray-50 py-8") do
          div(class: "max-w-2xl mx-auto px-4 sm:px-6 lg:px-8") do
            # Header
            div(class: "mb-8") do
              h1(class: "text-3xl font-bold text-gray-900") { "Add New Deadline" }
            end

            # Form
            div(class: "bg-white shadow rounded-lg p-6") do
              form_with(model: @deadline, url: deadlines_path, class: "space-y-6") do |f|
                # Course Name
                div do
                  label(for: "deadline_course_name", class: "block text-sm font-medium text-gray-700") do
                    "Course Name"
                  end
                  f.text_field(
                    :course_name,
                    class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm",
                    placeholder: "e.g., Philosophy of Science"
                  )
                  if @deadline.errors[:course_name].any?
                    p(class: "mt-2 text-sm text-red-600") { @deadline.errors[:course_name].join(", ") }
                  end
                end

                # Deadline Date
                div do
                  label(for: "deadline_deadline_date", class: "block text-sm font-medium text-gray-700") do
                    "Deadline Date"
                  end
                  f.date_field(
                    :deadline_date,
                    class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                  )
                  if @deadline.errors[:deadline_date].any?
                    p(class: "mt-2 text-sm text-red-600") { @deadline.errors[:deadline_date].join(", ") }
                  end
                end

                # Deadline Type
                div do
                  label(for: "deadline_deadline_type", class: "block text-sm font-medium text-gray-700") do
                    "Type"
                  end
                  f.select(
                    :deadline_type,
                    [ [ "Report", "report" ], [ "Exam", "exam" ] ],
                    { prompt: "Select type" },
                    class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                  )
                  if @deadline.errors[:deadline_type].any?
                    p(class: "mt-2 text-sm text-red-600") { @deadline.errors[:deadline_type].join(", ") }
                  end
                end

                # Description (optional)
                div do
                  label(for: "deadline_description", class: "block text-sm font-medium text-gray-700") do
                    "Description (Optional)"
                  end
                  f.text_area(
                    :description,
                    rows: 3,
                    class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm",
                    placeholder: "Any additional notes about this deadline..."
                  )
                end

                # Submit Buttons
                div(class: "flex gap-4") do
                  f.submit(
                    "Create Deadline",
                    class: "flex-1 inline-flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                  )

                  link_to(
                    "Cancel",
                    deadlines_path,
                    class: "flex-1 inline-flex justify-center py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                  )
                end
              end
            end
          end
        end
      end
    end
  end
end
