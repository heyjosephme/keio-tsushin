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
            "← Back to Profile",
            profile_path,
            class: "text-indigo-600 hover:text-indigo-800 text-sm font-medium"
          )
          h1(class: "mt-4 text-3xl font-bold text-gray-900") { "Edit Profile" }
        end
      end

      def render_flash_messages
        if flash[:alert]
          div(class: "mb-4 rounded-md bg-red-50 p-4") do
            p(class: "text-sm font-medium text-red-800") { flash[:alert] }
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
          h2(class: "text-lg font-semibold text-gray-900 mb-4") { "Account Information" }

          div(class: "space-y-4") do
            div do
              form.label :name, "Display Name", class: "block text-sm font-medium text-gray-700"
              form.text_field :name,
                placeholder: "Your name (optional)",
                class: "mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
            end

            div do
              label(class: "block text-sm font-medium text-gray-700") { "Email" }
              p(class: "mt-1 text-sm text-gray-600") { @user.email_address }
              p(class: "text-xs text-gray-400") { "Email cannot be changed" }
            end
          end
        end
      end

      def render_study_plan_section(form)
        div(class: "pt-6") do
          h2(class: "text-lg font-semibold text-gray-900 mb-4") { "Study Plan" }
          p(class: "text-sm text-gray-600 mb-4") do
            "Set your enrollment date and graduation goals to track your progress."
          end

          div(class: "space-y-4") do
            # Major
            div do
              form.label :major, "Major", class: "block text-sm font-medium text-gray-700"
              form.select :major,
                major_options,
                { include_blank: "Select your major" },
                class: "mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
              p(class: "text-xs text-gray-400 mt-1") { "Your major determines which courses are shown" }
            end

            # Enrolled Year and Semester
            div do
              label(class: "block text-sm font-medium text-gray-700 mb-1") { "Enrolled" }
              div(class: "grid grid-cols-2 gap-4") do
                div do
                  form.select :enrolled_year,
                    enrollment_year_options,
                    { include_blank: "Year" },
                    class: "block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
                end
                div do
                  form.select :enrolled_semester,
                    [ [ "Spring (April)", "spring" ], [ "Autumn (October)", "autumn" ] ],
                    { include_blank: "Semester" },
                    class: "block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
                end
              end
              p(class: "text-xs text-gray-400 mt-1") { "When did you start the program?" }
            end

            div do
              form.label :expected_graduation_year, "Expected Graduation Year", class: "block text-sm font-medium text-gray-700"
              form.select :expected_graduation_year,
                graduation_year_options,
                { include_blank: "Select year" },
                class: "mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
              p(class: "text-xs text-gray-400 mt-1") { "When do you plan to graduate?" }
            end

            div do
              form.label :credits_goal_per_year, "Credit Goal per Year", class: "block text-sm font-medium text-gray-700"
              form.number_field :credits_goal_per_year,
                min: 1,
                max: 50,
                placeholder: 30,
                class: "mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
              p(class: "text-xs text-gray-400 mt-1") { "How many credits do you aim to earn each year? (124 total needed)" }
            end
          end
        end
      end

      def major_options
        [
          [ "Economics (経済学部)", "economics" ],
          [ "Law (法学部)", "law" ],
          [ "Literature (文学部)", "literature" ]
        ]
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
            "Cancel",
            profile_path,
            class: "px-4 py-2 text-sm font-medium text-gray-700 hover:text-gray-900"
          )
          form.submit "Save Changes",
            class: "inline-flex justify-center rounded-md border border-transparent bg-indigo-600 py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 cursor-pointer"
        end
      end
    end
  end
end
