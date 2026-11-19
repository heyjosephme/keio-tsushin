# frozen_string_literal: true

module Views
  module Profiles
    class Edit < Views::Base
      include Phlex::Rails::Helpers::Flash
      include Phlex::Rails::Helpers::LinkTo
      include Phlex::Rails::Helpers::FormWith

      def initialize(user:)
        @user = user
      end

      def view_template
        render Components::Layout.new do
          div(class: "py-8") do
            div(class: "max-w-2xl mx-auto px-4 sm:px-6 lg:px-8") do
              render_flash_messages
              render_header
              render_form
            end
          end
        end
      end

      private

      def render_header
        div(class: "mb-8") do
          link_to(
            t(".back"),
            profile_path,
            class: "text-primary-700 hover:text-primary-900 text-sm font-medium"
          )
          h1(class: "mt-4 text-3xl font-bold text-gray-900") { t(".title") }
        end
      end

      def render_flash_messages
        if flash[:alert]
          div(class: "mb-4 rounded-md bg-danger-50 p-4") do
            p(class: "text-sm font-medium text-danger-800") { flash[:alert] }
          end
        end
      end

      def render_form
        div(class: "bg-white rounded-lg shadow-md p-6") do
          form_with(model: @user, url: profile_path, method: :patch, class: "space-y-6") do |form|
            render_account_section(form)
            render_study_plan_section(form)
            render_submit_button(form)
          end
        end
      end

      def render_account_section(form)
        div(class: "border-b border-gray-200 pb-6") do
          h2(class: "text-lg font-semibold text-gray-900 mb-4") { t(".account") }

          div(class: "space-y-4") do
            div do
              form.label :name, t(".name"), class: "block text-sm font-medium text-gray-700"
              form.text_field :name,
                placeholder: t(".name_placeholder"),
                class: "mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-primary-500 focus:outline-none focus:ring-primary-500"
            end

            div do
              label(class: "block text-sm font-medium text-gray-700") { t(".email") }
              p(class: "mt-1 text-sm text-gray-600") { @user.email_address }
              p(class: "text-xs text-gray-400") { t(".email_note") }
            end
          end
        end
      end

      def render_study_plan_section(form)
        div(class: "pt-6") do
          h2(class: "text-lg font-semibold text-gray-900 mb-4") { t(".study_plan") }
          p(class: "text-sm text-gray-600 mb-4") do
            t(".study_plan_intro")
          end

          div(class: "space-y-4") do
            # Major
            div do
              form.label :major, t(".major"), class: "block text-sm font-medium text-gray-700"
              form.select :major,
                major_options,
                { include_blank: t(".major_blank") },
                class: "mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-primary-500 focus:outline-none focus:ring-primary-500"
              p(class: "text-xs text-gray-400 mt-1") { t(".major_hint") }
            end

            # Enrolled Year and Semester
            div do
              label(class: "block text-sm font-medium text-gray-700 mb-1") { t(".enrolled") }
              div(class: "grid grid-cols-2 gap-4") do
                div do
                  form.select :enrolled_year,
                    enrollment_year_options,
                    { include_blank: t(".year") },
                    class: "block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-primary-500 focus:outline-none focus:ring-primary-500"
                end
                div do
                  form.select :enrolled_semester,
                    %w[spring autumn].map { |semester| [ t("shared.semesters.#{semester}"), semester ] },
                    { include_blank: t(".semester") },
                    class: "block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-primary-500 focus:outline-none focus:ring-primary-500"
                end
              end
              p(class: "text-xs text-gray-400 mt-1") { t(".enrolled_hint") }
            end

            div do
              form.label :expected_graduation_year, t(".graduation"), class: "block text-sm font-medium text-gray-700"
              form.select :expected_graduation_year,
                graduation_year_options,
                { include_blank: t(".graduation_blank") },
                class: "mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-primary-500 focus:outline-none focus:ring-primary-500"
              p(class: "text-xs text-gray-400 mt-1") { t(".graduation_hint") }
            end

            div do
              form.label :credits_goal_per_year, t(".credit_goal"), class: "block text-sm font-medium text-gray-700"
              form.number_field :credits_goal_per_year,
                min: 1,
                max: 50,
                placeholder: 30,
                class: "mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-primary-500 focus:outline-none focus:ring-primary-500"
              p(class: "text-xs text-gray-400 mt-1") { t(".credit_goal_hint") }
            end

            # The thesis isn't a catalog course, so its 8 credits are recorded here
            div do
              label(class: "inline-flex items-center gap-2 text-sm font-medium text-gray-700") do
                form.check_box :thesis_completed, class: "size-4 rounded border-gray-300 accent-primary-800"
                plain t(".thesis_completed")
              end
              p(class: "text-xs text-gray-400 mt-1") { t(".thesis_hint") }
            end
          end
        end
      end

      def major_options
        Course::MAJORS.map { |major| [ t("shared.majors.#{major}"), major ] }
      end

      def enrollment_year_options
        (2015..Date.today.year).to_a.reverse.map { |year| [ year.to_s, year ] }
      end

      def graduation_year_options
        (Date.today.year..(Date.today.year + 10)).to_a.map { |year| [ year.to_s, year ] }
      end

      def render_submit_button(form)
        div(class: "pt-6 flex justify-end gap-4") do
          link_to(
            t("shared.cancel"),
            profile_path,
            class: "px-4 py-2 text-sm font-medium text-gray-700 hover:text-gray-900"
          )
          form.submit t(".submit"),
            class: "inline-flex justify-center rounded-md border border-transparent bg-primary-800 py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2 cursor-pointer"
        end
      end
    end
  end
end
