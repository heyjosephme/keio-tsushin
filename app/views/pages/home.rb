# frozen_string_literal: true

module Views
  module Pages
    class Home < Views::Base
      include Phlex::Rails::Helpers::LinkTo

      def view_template
        render Components::Layout.new(show_footer: false) do
          # Hero Section
          div(class: "bg-gradient-to-br from-primary-50 via-white to-primary-50") do
            div(class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20") do
              div(class: "text-center") do
                h1(class: "text-5xl font-bold text-gray-900 mb-4") do
                  plain "慶應義塾大学"
                  br
                  plain "Keio Tsushin"
                end

                p(class: "text-xl text-gray-600 mb-8") do
                  plain t(".subtitle")
                end

                # CTA Buttons
                div(class: "mb-16 flex flex-col sm:flex-row gap-4 justify-center") do
                  link_to(
                    t(".deadlines"),
                    deadlines_path,
                    class: "inline-flex items-center justify-center px-8 py-4 text-lg font-medium text-white bg-primary-800 hover:bg-primary-700 rounded-lg shadow-lg transition-colors"
                  )
                  link_to(
                    t(".dashboard"),
                    dashboard_enrollments_path,
                    class: "inline-flex items-center justify-center px-8 py-4 text-lg font-medium text-white bg-success-600 hover:bg-success-700 rounded-lg shadow-lg transition-colors"
                  )
                  link_to(
                    t(".planner"),
                    enrollments_path,
                    class: "inline-flex items-center justify-center px-8 py-4 text-lg font-medium text-primary-700 bg-white hover:bg-primary-50 rounded-lg shadow-lg transition-colors border-2 border-primary-600"
                  )
                end
              end

              # Features Grid
              div(class: "grid md:grid-cols-3 gap-8 mt-16") do
                render_feature_card(
                  icon: "📅",
                  title: t(".feature_deadlines_title"),
                  description: t(".feature_deadlines_text")
                )
                render_feature_card(
                  icon: "📝",
                  title: t(".feature_reports_title"),
                  description: t(".feature_reports_text")
                )
                render_feature_card(
                  icon: "🎓",
                  title: t(".feature_credits_title"),
                  description: t(".feature_credits_text")
                )
              end
            end
          end
        end

        render Components::Footer.new
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
