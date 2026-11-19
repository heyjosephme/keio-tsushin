# frozen_string_literal: true

module Views
  module Enrollments
    class Dashboard < Views::Base
      include Phlex::Rails::Helpers::Flash
      include Phlex::Rails::Helpers::LinkTo

      TOTAL_CREDITS_REQUIRED = Enrollment::CREDITS_REQUIRED

      def initialize(credit_stats:, credits_by_field:, graduation:)
        @credit_stats = credit_stats
        @credits_by_field = credits_by_field
        @graduation = graduation
      end

      def view_template
        render Components::Layout.new do
          div(class: "py-8") do
            div(class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8") do
              render_flash_messages
              render_header
              render_overall_progress
              render_graduation_check
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
          div(class: "mb-4 rounded-md bg-success-50 p-4") do
            p(class: "text-sm font-medium text-success-800") { flash[:notice] }
          end
        end

        if flash[:alert]
          div(class: "mb-4 rounded-md bg-danger-50 p-4") do
            p(class: "text-sm font-medium text-danger-800") { flash[:alert] }
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
              class: "bg-primary-800 h-4 rounded-full transition-all duration-300",
              style: "width: #{[ percentage, 100 ].min}%"
            )
          end

          p(class: "text-center text-sm text-gray-600") do
            t(".percent_complete", percent: percentage)
          end

          # Credits beyond an area's minimum don't make up for a shortfall in another area
          remaining = @graduation.remaining

          if @graduation.met?
            p(class: "text-center text-sm text-success-600 font-semibold mt-4") do
              t(".requirement_met")
            end
          else
            p(class: "text-center text-sm text-gray-600 mt-4") do
              t(".remaining", count: remaining)
            end
          end
        end
      end

      # Every graduation rule as a checklist: one card per section, with its sub-rules
      def render_graduation_check
        div(class: "bg-white rounded-lg shadow mb-8") do
          div(class: "px-6 py-4 border-b border-gray-200") do
            h2(class: "text-xl font-semibold text-gray-900") { t("graduation.title") }
            p(class: "mt-1 text-sm text-gray-500") { t("graduation.intro") }
            div(class: "mt-3 flex flex-wrap gap-x-5 gap-y-1 text-xs text-gray-600") do
              render_legend(:met)
              render_legend(:on_track)
              render_legend(:open)
            end
          end

          div(class: "divide-y divide-gray-100") do
            @graduation.sections.each { |section| render_section(section) }
          end

          p(class: "px-6 py-3 border-t border-gray-100 text-xs text-gray-500") { t("graduation.not_checked") }
        end
      end

      REQUIREMENT_ICONS = {
        met: [ :completed, "text-success-600" ],
        on_track: [ :clock, "text-primary-500" ],
        open: [ :planned, "text-gray-300" ]
      }.freeze

      def requirement_state(requirement)
        return :met if requirement.met?

        requirement.on_track? ? :on_track : :open
      end

      def render_requirement_icon(state, size: "size-4")
        name, color = REQUIREMENT_ICONS.fetch(state)
        render Components::Icon.new(name, label: t("graduation.legend_#{state}"), class: "#{size} shrink-0 #{color}")
      end

      def render_legend(state)
        name, color = REQUIREMENT_ICONS.fetch(state)

        span(class: "inline-flex items-center gap-1.5") do
          render Components::Icon.new(name, class: "size-4 shrink-0 #{color}")
          plain t("graduation.legend_#{state}")
        end
      end

      def render_section(section)
        div(class: "p-6") do
          div(class: "flex items-center justify-between gap-4 mb-2") do
            h3(class: "flex items-center gap-2 text-base font-semibold text-primary-900") do
              render_requirement_icon(section.all_met? ? :met : (section.all_on_track? ? :on_track : :open), size: "size-5")
              plain section.label
            end
            render_requirement_numbers(section, strong: true)
          end

          div(class: "w-full bg-gray-200 rounded-full h-2.5 flex overflow-hidden") do
            done = requirement_percent(section.completed, section)
            div(class: "bg-primary-800 h-2.5", style: "width: #{done}%")
            div(class: "bg-primary-200 h-2.5", style: "width: #{[ requirement_percent(section.planned, section) - done, 0 ].max}%")
          end

          if section.children.any?
            ul(class: "mt-4 space-y-2") do
              section.children.each { |child| render_requirement(child) }
            end
          end

          p(class: "mt-3 text-xs text-gray-500") { t("graduation.notes.#{section.key}") }
        end
      end

      def render_requirement(requirement, depth: 0)
        li do
          div(class: "flex items-center justify-between gap-4 text-sm #{depth.zero? ? "text-gray-900" : "text-gray-600"}") do
            span(class: "flex items-center gap-2") do
              render_requirement_icon(requirement_state(requirement))
              span(class: depth.zero? ? "font-medium" : nil) { requirement.label }
              if requirement.key == :required_language && @graduation.required_language
                span(class: "text-xs text-gray-500") do
                  "(#{t("graduation.language", language: t("graduation.languages.#{@graduation.required_language}", default: @graduation.required_language))})"
                end
              end
            end
            render_requirement_numbers(requirement)
          end

          if requirement.children.any?
            ul(class: "mt-2 ml-6 space-y-2 border-l border-gray-100 pl-4") do
              requirement.children.each { |child| render_requirement(child, depth: depth + 1) }
            end
          end
        end
      end

      # "4 / 32 credits · plan: 20"; the plan figure only when it adds something
      def render_requirement_numbers(requirement, strong: false)
        span(class: "shrink-0 text-right text-sm #{strong ? "font-semibold text-gray-900" : "text-gray-700"}") do
          if requirement.unit == :done
            plain t(requirement.met? ? "graduation.units.done" : "graduation.units.not_done")
          else
            plain t("graduation.units.#{requirement.unit}", completed: requirement.completed, required: requirement.required)
            if requirement.planned > requirement.completed
              span(class: "ml-2 text-xs font-normal text-gray-500") { t("graduation.planned", planned: requirement.planned) }
            end
          end
        end
      end

      def requirement_percent(credits, requirement)
        [ credits * 100.0 / requirement.required, 100 ].min.round(1)
      end

      def render_status_cards
        div(class: "grid grid-cols-1 md:grid-cols-3 gap-6 mb-8") do
          render_status_card(
            title: t(".completed"),
            credits: @credit_stats[:completed],
            color: "green",
            icon: :completed
          )

          render_status_card(
            title: t(".in_progress"),
            credits: @credit_stats[:in_progress],
            color: "blue",
            icon: :report_submitted
          )

          render_status_card(
            title: t(".planned"),
            credits: @credit_stats[:planned],
            color: "gray",
            icon: :planned
          )
        end
      end

      def render_status_card(title:, credits:, color:, icon:)
        bg_color = {
          "green" => "bg-success-50",
          "blue" => "bg-primary-50",
          "gray" => "bg-gray-50"
        }[color]

        text_color = {
          "green" => "text-success-700",
          "blue" => "text-primary-700",
          "gray" => "text-gray-700"
        }[color]

        border_color = {
          "green" => "border-success-200",
          "blue" => "border-primary-200",
          "gray" => "border-gray-200"
        }[color]

        div(class: "bg-white rounded-lg shadow border-l-4 #{border_color} p-6") do
          div(class: "flex items-center justify-between mb-2") do
            h3(class: "text-lg font-semibold text-gray-900") { title }
            render Components::Icon.new(icon, class: "size-6 shrink-0 #{text_color}")
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
          td(class: "px-6 py-4 whitespace-nowrap text-sm text-success-600") do
            stats[:completed]
          end
          td(class: "px-6 py-4 whitespace-nowrap text-sm text-primary-600") do
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
              class: "inline-flex justify-center items-center px-6 py-3 border border-transparent rounded-md shadow-sm text-base font-medium text-white bg-primary-800 hover:bg-primary-700"
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
