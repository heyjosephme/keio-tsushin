# frozen_string_literal: true

module Views
  module Pages
    class Home < Views::Base
      include Phlex::Rails::Helpers::LinkTo

      def view_template
        div(class: "min-h-screen bg-gradient-to-br from-indigo-50 via-white to-blue-50") do
          # Hero Section
          div(class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20") do
            div(class: "text-center") do
              # Title
              h1(class: "text-5xl font-bold text-gray-900 mb-4") do
                plain "慶應義塾大学"
                br
                plain "Keio Tsushin"
              end

              p(class: "text-xl text-gray-600 mb-8") do
                plain "Distance Learning Credit Management System"
              end

              # CTA Buttons
              div(class: "mb-16 flex flex-col sm:flex-row gap-4 justify-center") do
                link_to(
                  "📅 Deadlines Calendar",
                  deadlines_path,
                  class: "inline-flex items-center justify-center px-8 py-4 text-lg font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow-lg transition-colors"
                )
                link_to(
                  "📚 Course Planner",
                  enrollments_path,
                  class: "inline-flex items-center justify-center px-8 py-4 text-lg font-medium text-indigo-600 bg-white hover:bg-indigo-50 rounded-lg shadow-lg transition-colors border-2 border-indigo-600"
                )
              end
            end

            # Features Grid
            div(class: "grid md:grid-cols-3 gap-8 mt-16") do
              # Feature 1: Deadline Tracking
              render_feature_card(
                icon: "📅",
                title: "Deadline Tracking",
                description: "Track report submissions and exam dates for all your courses in one place."
              )

              # Feature 2: Report Management
              render_feature_card(
                icon: "📝",
                title: "Report Management",
                description: "Keep track of which reports you need to submit before applying for exams."
              )

              # Feature 3: Credit Planning
              render_feature_card(
                icon: "🎓",
                title: "Credit Planning",
                description: "Plan your path to graduation by managing course credits and requirements."
              )
            end
          end

          # Footer
          div(class: "mt-20 text-center pb-8") do
            p(class: "text-sm text-gray-500") do
              plain "Built for Keio University Distance Learning Students"
            end
          end
        end
      end

      private

      def render_feature_card(icon:, title:, description:)
        div(class: "bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow") do
          div(class: "text-4xl mb-4") { icon }
          h3(class: "text-xl font-semibold text-gray-900 mb-2") { title }
          p(class: "text-gray-600") { description }
        end
      end
    end
  end
end
