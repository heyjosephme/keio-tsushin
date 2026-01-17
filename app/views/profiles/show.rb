# frozen_string_literal: true

module Views
  module Profiles
    class Show < Views::Base
      include Phlex::Rails::Helpers::Flash
      include Phlex::Rails::Helpers::LinkTo

      def initialize(user:)
        @user = user
      end

      def view_template
        render Components::Layout.new do
          div(class: "py-8") do
            div(class: "max-w-2xl mx-auto px-4 sm:px-6 lg:px-8") do
              render_flash_messages
              render_header
              render_profile_card
              render_study_plan
            end
          end
        end
      end

      private

      def render_header
        div(class: "mb-8 flex justify-between items-center") do
          h1(class: "text-3xl font-bold text-gray-900") { "Profile" }
          link_to(
            "Edit Profile",
            edit_profile_path,
            class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700"
          )
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

      def render_profile_card
        div(class: "bg-white rounded-lg shadow-md p-6 mb-6") do
          h2(class: "text-xl font-semibold text-gray-900 mb-4") { "Account Information" }

          dl(class: "space-y-4") do
            render_field("Name", @user.name.presence || "Not set")
            render_field("Email", @user.email_address)
          end
        end
      end

      def render_study_plan
        div(class: "bg-white rounded-lg shadow-md p-6") do
          h2(class: "text-xl font-semibold text-gray-900 mb-4") { "Study Plan" }

          dl(class: "space-y-4") do
            render_field("Enrolled", format_enrollment(@user.enrolled_year, @user.enrolled_semester))
            render_field("Expected Graduation", format_year(@user.expected_graduation_year))
            render_field("Credit Goal per Year", format_credits(@user.credits_goal_per_year))
          end

          if study_plan_complete?
            render_progress_summary
          else
            div(class: "mt-6 p-4 bg-amber-50 rounded-lg") do
              p(class: "text-sm text-amber-700") do
                "Complete your study plan to see personalized progress insights."
              end
              link_to(
                "Set up study plan",
                edit_profile_path,
                class: "mt-2 inline-block text-sm font-medium text-amber-800 underline"
              )
            end
          end
        end
      end

      def render_field(label, value)
        div(class: "flex justify-between") do
          dt(class: "text-sm font-medium text-gray-500") { label }
          dd(class: "text-sm text-gray-900") { value }
        end
      end

      def render_progress_summary
        years_remaining = @user.expected_graduation_year - Date.today.year
        credits_needed = 124 - Enrollment.where(user: @user, status: "completed").sum { |e| e.credits || 0 }
        credits_per_year_needed = years_remaining > 0 ? (credits_needed.to_f / years_remaining).ceil : credits_needed

        div(class: "mt-6 p-4 bg-indigo-50 rounded-lg") do
          h3(class: "text-sm font-semibold text-indigo-900 mb-2") { "Progress Insight" }

          if years_remaining > 0
            p(class: "text-sm text-indigo-700") do
              "To graduate by #{@user.expected_graduation_year}, you need ~#{credits_per_year_needed} credits/year (#{credits_needed} credits remaining over #{years_remaining} years)."
            end

            if @user.credits_goal_per_year && credits_per_year_needed > @user.credits_goal_per_year
              p(class: "text-sm text-amber-700 mt-2") do
                "Your goal of #{@user.credits_goal_per_year} credits/year may need adjustment."
              end
            end
          else
            p(class: "text-sm text-indigo-700") do
              "#{credits_needed} credits remaining to reach graduation requirement."
            end
          end
        end
      end

      def format_enrollment(year, semester)
        return "Not set" unless year && semester

        semester_label = semester == "spring" ? "Spring (April)" : "Autumn (October)"
        "#{year} #{semester_label}"
      end

      def format_year(year)
        year ? year.to_s : "Not set"
      end

      def format_credits(credits)
        credits ? "#{credits} credits" : "Not set"
      end

      def study_plan_complete?
        @user.enrolled_year.present? && @user.expected_graduation_year.present?
      end
    end
  end
end
