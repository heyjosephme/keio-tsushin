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
          p(class: "text-gray-600 mb-5") { "This is a personal project. If you're interested in using it or have questions:" }

          div(class: "flex flex-col gap-3") do
            contact_link("https://github.com/heyjosephme", "github.com/heyjosephme") do
              svg_github
            end

            contact_link("mailto:contact@heyjoseph.me", "contact@heyjoseph.me") do
              svg_mail
            end
          end

          p(class: "text-sm text-gray-400 mt-5") do
            "Public registration is not available. Please contact me if you'd like an account."
          end
        end
      end

      def contact_link(href, text, &icon)
        a(
          href: href,
          target: href.start_with?("mailto") ? nil : "_blank",
          class: "inline-flex items-center gap-2 text-gray-600 hover:text-indigo-600 transition"
        ) do
          yield
          span(class: "text-sm") { text }
        end
      end

      def svg_github
        svg(xmlns: "http://www.w3.org/2000/svg", width: "18", height: "18", viewBox: "0 0 24 24",
            fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
            stroke_linejoin: "round") do |s|
          s.path(d: "M15 22v-4a4.8 4.8 0 0 0-1-3.5c3 0 6-2 6-5.5.08-1.25-.27-2.48-1-3.5.28-1.15.28-2.35 0-3.5 0 0-1 0-3 1.5-2.64-.5-5.36-.5-8 0C6 2 5 2 5 2c-.3 1.15-.3 2.35 0 3.5A5.403 5.403 0 0 0 4 9c0 3.5 3 5.5 6 5.5-.39.49-.68 1.05-.85 1.65-.17.6-.22 1.23-.15 1.85v4")
          s.path(d: "M9 18c-4.51 2-5-2-7-2")
        end
      end

      def svg_mail
        svg(xmlns: "http://www.w3.org/2000/svg", width: "18", height: "18", viewBox: "0 0 24 24",
            fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
            stroke_linejoin: "round") do |s|
          s.rect(width: "20", height: "16", x: "2", y: "4", rx: "2")
          s.path(d: "m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7")
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
