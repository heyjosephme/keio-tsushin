# frozen_string_literal: true

module Views
  module Deadlines
    class Index < Views::Base
      include Phlex::Rails::Helpers::Flash
      include Phlex::Rails::Helpers::FormAuthenticityToken

      def initialize(deadlines:, upcoming:, past:)
        @deadlines = deadlines
        @upcoming = upcoming
        @past = past
      end

      def view_template
        div(class: "min-h-screen bg-gray-50 py-8") do
          div(class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8") do
            # Flash messages
            render_flash_messages

            # Header
            div(class: "mb-8 flex justify-between items-center") do
              h1(class: "text-3xl font-bold text-gray-900") { "Keio Tsushin - Deadlines Calendar" }
              a(
                href: new_deadline_path,
                class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              ) do
                plain "+"
                span(class: "ml-2") { "Add Deadline" }
              end
            end

            # Upcoming Deadlines
            div(class: "mb-12") do
              h2(class: "text-2xl font-semibold text-gray-800 mb-4") { "Upcoming Deadlines" }

              if @upcoming.any?
                div(class: "grid gap-4 md:grid-cols-2 lg:grid-cols-3") do
                  @upcoming.each do |deadline|
                    render_deadline_card(deadline)
                  end
                end
              else
                p(class: "text-gray-500 italic") { "No upcoming deadlines." }
              end
            end

            # Past Deadlines
            if @past.any?
              div do
                h2(class: "text-2xl font-semibold text-gray-800 mb-4") { "Past Deadlines" }
                div(class: "grid gap-4 md:grid-cols-2 lg:grid-cols-3") do
                  @past.each do |deadline|
                    render_deadline_card(deadline, past: true)
                  end
                end
              end
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

      def render_deadline_card(deadline, past: false)
        div(class: "bg-white rounded-lg shadow p-6 #{past ? 'opacity-60' : ''}") do
          div(class: "flex justify-between items-start mb-2") do
            span(
              class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{deadline_type_color(deadline.deadline_type)}"
            ) do
              deadline.deadline_type.capitalize
            end

            form(action: deadline_path(deadline), method: "post", class: "inline") do
              input(type: "hidden", name: "_method", value: "delete")
              input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
              button(
                type: "submit",
                class: "text-red-600 hover:text-red-800 text-sm",
                data: { turbo_confirm: "Are you sure?" }
              ) { "Delete" }
            end
          end

          h3(class: "text-lg font-semibold text-gray-900 mb-2") { deadline.course_name }

          p(class: "text-sm text-gray-600 mb-1") do
            strong { "Date: " }
            span { deadline.deadline_date.strftime("%B %d, %Y") }
          end

          if deadline.description.present?
            p(class: "text-sm text-gray-500 mt-2") { deadline.description }
          end
        end
      end

      def deadline_type_color(type)
        case type
        when "report"
          "bg-blue-100 text-blue-800"
        when "exam"
          "bg-red-100 text-red-800"
        else
          "bg-gray-100 text-gray-800"
        end
      end
    end
  end
end
