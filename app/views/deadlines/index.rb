# frozen_string_literal: true

module Views
  module Deadlines
    class Index < Views::Base
      def initialize(current_date:, events:)
        @current_date = current_date
        @events = events
      end

      def view_template
        render Components::Layout.new do
          div(class: "py-8") do
            div(class: "max-w-5xl mx-auto px-4 sm:px-6 lg:px-8") do
              h1(class: "text-3xl font-bold text-gray-900 mb-6") { t(".title") }

              div(class: "mb-6") { render Components::NextDeadlines.new }

              render Components::Calendar.new(current_date: @current_date, events: @events)
            end
          end
        end
      end
    end
  end
end
