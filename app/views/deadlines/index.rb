# frozen_string_literal: true

module Views
  module Deadlines
    class Index < Views::Base
      include Phlex::Rails::Helpers::Flash
      include Phlex::Rails::Helpers::FormAuthenticityToken
      include Phlex::Rails::Helpers::LinkTo

      def initialize(current_date:, deadlines:, upcoming:)
        @current_date = current_date
        @deadlines = deadlines
        @upcoming = upcoming
      end

      def view_template
        div(class: "min-h-screen bg-gray-50 py-8") do
          div(class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8") do
            render_flash_messages
            render_header

            # Two-column layout: Calendar + Upcoming sidebar
            div(class: "grid grid-cols-1 lg:grid-cols-3 gap-8") do
              # Calendar (2/3 width on large screens)
              div(class: "lg:col-span-2") do
                render Components::Calendar.new(
                  current_date: @current_date,
                  deadlines: @deadlines
                )
              end

              # Upcoming deadlines sidebar (1/3 width)
              div(class: "lg:col-span-1") do
                render_upcoming_sidebar
              end
            end
          end
        end
      end

      private

      def render_header
        div(class: "mb-8") do
          div(class: "mb-4") do
            link_to(
              "← Home",
              root_path,
              class: "text-indigo-600 hover:text-indigo-800 text-sm font-medium"
            )
          end

          div(class: "flex justify-between items-center") do
            h1(class: "text-3xl font-bold text-gray-900") { "Deadlines Calendar" }
            a(
              href: new_deadline_path,
              class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700"
            ) do
              plain "+"
              span(class: "ml-2") { "Add Deadline" }
            end
          end
        end
      end

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

      def render_upcoming_sidebar
        div(class: "bg-white rounded-lg shadow p-6") do
          h2(class: "text-lg font-semibold text-gray-900 mb-4") { "Upcoming Deadlines" }

          if @upcoming.any?
            div(class: "space-y-3") do
              @upcoming.each do |deadline|
                render_upcoming_item(deadline)
              end
            end
          else
            p(class: "text-gray-500 text-sm italic") { "No upcoming deadlines." }
          end
        end
      end

      def render_upcoming_item(deadline)
        days_until = (deadline.deadline_date - Date.today).to_i
        urgency_color = case days_until
        when 0..3 then "border-l-red-500"
        when 4..7 then "border-l-yellow-500"
        else "border-l-gray-300"
        end

        div(class: "border-l-4 #{urgency_color} pl-3 py-2") do
          div(class: "flex justify-between items-start") do
            div do
              p(class: "font-medium text-gray-900 text-sm") { deadline.course_name }
              p(class: "text-xs text-gray-500") do
                plain deadline.deadline_date.strftime("%b %d")
                span(class: "mx-1") { "·" }
                plain deadline.deadline_type.capitalize
              end
            end

            span(class: "text-xs font-medium #{days_until <= 3 ? 'text-red-600' : 'text-gray-500'}") do
              if days_until == 0
                "Today"
              elsif days_until == 1
                "Tomorrow"
              else
                "#{days_until}d"
              end
            end
          end

          # Delete button
          form(action: deadline_path(deadline), method: "post", class: "mt-1") do
            input(type: "hidden", name: "_method", value: "delete")
            input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
            button(
              type: "submit",
              class: "text-xs text-red-600 hover:text-red-800",
              data: { turbo_confirm: "Delete this deadline?" }
            ) { "Delete" }
          end
        end
      end
    end
  end
end
