# frozen_string_literal: true

module Views
  module Pages
    class About < Views::Base
      include Phlex::Rails::Helpers::LinkTo

      def view_template
        render Components::Layout.new do
          div(class: "max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12") do
            render_header
            render_about_section
            render_features_section
            render_contact_section
            render_tech_stack
          end
        end
      end

      private

      def render_header
        div(class: "text-center mb-12") do
          h1(class: "text-4xl font-bold text-gray-900 mb-4") { "About Keio Tsushin" }
          p(class: "text-xl text-gray-600") do
            "A personal credit management system for Keio University distance learning students"
          end
        end
      end

      def render_about_section
        section(class: "bg-white rounded-lg shadow-md p-8 mb-8") do
          h2(class: "text-2xl font-semibold text-gray-900 mb-4") { "What is this?" }
          div(class: "prose text-gray-600 space-y-4") do
            p do
              "Keio Tsushin is a personal project built to help track credits, deadlines, and course progress for Keio University's correspondence education program (通信教育課程)."
            end
            p do
              "The correspondence program requires students to complete 124 credits through a combination of reports, exams, and schooling sessions. This tool helps manage that journey."
            end
          end
        end
      end

      def render_features_section
        section(class: "bg-white rounded-lg shadow-md p-8 mb-8") do
          h2(class: "text-2xl font-semibold text-gray-900 mb-6") { "Features" }

          div(class: "grid md:grid-cols-2 gap-6") do
            feature_card(
              "Course Planner",
              "Organize courses by exam season with a kanban-style board. Track status from planned to completed."
            )
            feature_card(
              "Credit Dashboard",
              "Monitor progress toward the 124 credit graduation requirement. See credits by category and status."
            )
            feature_card(
              "Deadline Calendar",
              "Never miss a report submission or exam application deadline with the monthly calendar view."
            )
            feature_card(
              "Season Tracking",
              "View upcoming exam seasons with report deadlines, application periods, and exam dates."
            )
          end
        end
      end

      def feature_card(title, description)
        div(class: "border border-gray-200 rounded-lg p-4") do
          h3(class: "font-semibold text-gray-900 mb-2") { title }
          p(class: "text-sm text-gray-600") { description }
        end
      end

      def render_contact_section
        section(class: "bg-white rounded-lg shadow-md p-8 mb-8") do
          h2(class: "text-2xl font-semibold text-gray-900 mb-4") { "Contact" }
          div(class: "text-gray-600 space-y-3") do
            p { "This is a personal project. If you're interested in using it or have questions:" }

            div(class: "flex flex-col sm:flex-row gap-4 mt-4") do
              a(
                href: "https://github.com/heyjosephme",
                target: "_blank",
                class: "inline-flex items-center px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
              ) do
                span(class: "mr-2") { "GitHub" }
                span(class: "text-gray-400") { "github.com/heyjosephme" }
              end

              a(
                href: "mailto:contact@heyjoseph.me",
                class: "inline-flex items-center px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
              ) do
                span(class: "mr-2") { "Email" }
                span(class: "text-gray-400") { "contact@heyjoseph.me" }
              end
            end

            p(class: "text-sm text-gray-500 mt-4") do
              "Note: Public registration is not available. Please contact me if you'd like an account."
            end
          end
        end
      end

      def render_tech_stack
        section(class: "bg-gray-100 rounded-lg p-8") do
          h2(class: "text-2xl font-semibold text-gray-900 mb-4") { "Built With" }

          div(class: "flex flex-wrap gap-2") do
            %w[Ruby Rails Phlex Hotwire Tailwind SQLite Kamal].each do |tech|
              span(class: "px-3 py-1 bg-white rounded-full text-sm text-gray-700 shadow-sm") { tech }
            end
          end
        end
      end
    end
  end
end
