# frozen_string_literal: true

module Views
  module Enrollments
    class Dashboard < Views::Base
      include Phlex::Rails::Helpers::Flash
      include Phlex::Rails::Helpers::LinkTo

      TOTAL_CREDITS_REQUIRED = Enrollment::CREDITS_REQUIRED

      def initialize(credit_stats:, credits_by_field:)
        @credit_stats = credit_stats
        @credits_by_field = credits_by_field
      end

      def view_template
        render Components::Layout.new do
          div(class: "py-8") do
            div(class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8") do
              render_flash_messages
              render_header
              render_overall_progress
              render_status_cards
              render_field_breakdown
              render_quick_actions
            end
          end
        end
      end

      private

      def render_header
        div(class: "mb-8") do
          h1(class: "text-3xl font-bold text-gray-900") { t(".title") }
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

      def render_overall_progress
        completed = @credit_stats[:completed]
        percentage = ((completed.to_f / TOTAL_CREDITS_REQUIRED) * 100).round(1)

        div(class: "mb-8 bg-white rounded-lg shadow-lg p-8") do
          div(class: "text-center mb-4") do
            p(class: "text-5xl font-bold text-gray-900") do
              span { completed.to_s }
              span(class: "text-2xl text-gray-500") { " / #{TOTAL_CREDITS_REQUIRED}" }
            end
            p(class: "text-sm text-gray-600 mt-2") { t(".completed_credits") }
          end

          # Progress bar
          div(class: "w-full bg-gray-200 rounded-full h-4 mb-2") do
            div(
              class: "bg-indigo-600 h-4 rounded-full transition-all duration-300",
              style: "width: #{[ percentage, 100 ].min}%"
            )
          end

          p(class: "text-center text-sm text-gray-600") do
            t(".percent_complete", percent: percentage)
          end

          if completed >= TOTAL_CREDITS_REQUIRED
            p(class: "text-center text-sm text-green-600 font-semibold mt-4") do
              t(".requirement_met")
            end
          else
            p(class: "text-center text-sm text-gray-600 mt-4") do
              t(".remaining", count: TOTAL_CREDITS_REQUIRED - completed)
            end
          end
        end
      end

      def render_status_cards
        div(class: "grid grid-cols-1 md:grid-cols-3 gap-6 mb-8") do
          render_status_card(
            title: t(".completed"),
            credits: @credit_stats[:completed],
            color: "green",
            icon: "✓"
          )

          render_status_card(
            title: t(".in_progress"),
            credits: @credit_stats[:in_progress],
            color: "blue",
            icon: "→"
          )

          render_status_card(
            title: t(".planned"),
            credits: @credit_stats[:planned],
            color: "gray",
            icon: "○"
          )
        end
      end

      def render_status_card(title:, credits:, color:, icon:)
        bg_color = {
          "green" => "bg-green-50",
          "blue" => "bg-blue-50",
          "gray" => "bg-gray-50"
        }[color]

        text_color = {
          "green" => "text-green-700",
          "blue" => "text-blue-700",
          "gray" => "text-gray-700"
        }[color]

        border_color = {
          "green" => "border-green-200",
          "blue" => "border-blue-200",
          "gray" => "border-gray-200"
        }[color]

        div(class: "bg-white rounded-lg shadow border-l-4 #{border_color} p-6") do
          div(class: "flex items-center justify-between mb-2") do
            h3(class: "text-lg font-semibold text-gray-900") { title }
            span(class: "text-2xl") { icon }
          end

          p(class: "text-3xl font-bold #{text_color}") do
            span { credits.to_s }
            span(class: "text-lg text-gray-600") { t(".credits_unit") }
          end
        end
      end

      def render_field_breakdown
        div(class: "bg-white rounded-lg shadow mb-8") do
          div(class: "px-6 py-4 border-b border-gray-200") do
            h2(class: "text-xl font-semibold text-gray-900") { t(".by_field") }
          end

          div(class: "overflow-x-auto") do
            table(class: "min-w-full divide-y divide-gray-200") do
              thead(class: "bg-gray-50") do
                tr do
                  th(class: "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider") do
                    t(".field")
                  end
                  th(class: "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider") do
                    t(".completed")
                  end
                  th(class: "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider") do
                    t(".in_progress")
                  end
                  th(class: "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider") do
                    t(".planned")
                  end
                  th(class: "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider") do
                    t(".total")
                  end
                end
              end

              tbody(class: "bg-white divide-y divide-gray-200") do
                Course::FIELDS.each { |field| render_field_row(t("shared.fields.#{field}"), field) }
              end
            end
          end

          if @credits_by_field.values.all? { |stats| stats[:total] == 0 }
            div(class: "px-6 py-8 text-center") do
              p(class: "text-gray-500 text-sm") do
                t(".empty")
              end
            end
          end
        end
      end

      def render_field_row(label, field_key)
        stats = @credits_by_field[field_key]
        return unless stats

        tr do
          td(class: "px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900") do
            label
          end
          td(class: "px-6 py-4 whitespace-nowrap text-sm text-green-600") do
            stats[:completed]
          end
          td(class: "px-6 py-4 whitespace-nowrap text-sm text-blue-600") do
            stats[:in_progress]
          end
          td(class: "px-6 py-4 whitespace-nowrap text-sm text-gray-600") do
            stats[:planned]
          end
          td(class: "px-6 py-4 whitespace-nowrap text-sm font-semibold text-gray-900") do
            stats[:total]
          end
        end
      end

      def render_quick_actions
        div(class: "bg-white rounded-lg shadow p-6") do
          h2(class: "text-xl font-semibold text-gray-900 mb-4") { t(".quick_actions") }

          div(class: "flex flex-col sm:flex-row gap-4") do
            link_to(
              t(".view_planner"),
              enrollments_path,
              class: "inline-flex justify-center items-center px-6 py-3 border border-transparent rounded-md shadow-sm text-base font-medium text-white bg-indigo-600 hover:bg-indigo-700"
            )

            link_to(
              t(".add_course"),
              new_enrollment_path,
              class: "inline-flex justify-center items-center px-6 py-3 border border-gray-300 rounded-md shadow-sm text-base font-medium text-gray-700 bg-white hover:bg-gray-50"
            )
          end
        end
      end
    end
  end
end
