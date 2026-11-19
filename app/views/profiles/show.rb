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
          h1(class: "text-3xl font-bold text-gray-900") { t(".title") }
          link_to(
            t(".edit"),
            edit_profile_path,
            class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-primary-800 hover:bg-primary-700"
          )
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

      def render_profile_card
        div(class: "bg-white rounded-lg shadow-md p-6 mb-6") do
          h2(class: "text-xl font-semibold text-gray-900 mb-4") { t(".account") }

          dl(class: "space-y-4") do
            render_field(t(".name"), @user.name.presence || t("shared.not_set"))
            render_field(t(".email"), @user.email_address)
          end
        end
      end

      def render_study_plan
        div(class: "bg-white rounded-lg shadow-md p-6") do
          h2(class: "text-xl font-semibold text-gray-900 mb-4") { t(".study_plan") }

          dl(class: "space-y-4") do
            render_field(t(".major"), format_major(@user.major))
            render_field(t(".enrolled"), format_enrollment(@user.enrolled_year, @user.enrolled_semester))
            render_field(t(".graduation"), format_year(@user.expected_graduation_year))
            render_field(t(".credit_goal"), format_credits(@user.credits_goal_per_year))
          end

          if study_plan_complete?
            render_progress_summary
          else
            div(class: "mt-6 p-4 bg-warning-50 rounded-lg") do
              p(class: "text-sm text-warning-700") do
                t(".incomplete")
              end
              link_to(
                t(".setup"),
                edit_profile_path,
                class: "mt-2 inline-block text-sm font-medium text-warning-800 underline"
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

        div(class: "mt-6 p-4 bg-primary-50 rounded-lg") do
          h3(class: "text-sm font-semibold text-primary-900 mb-2") { t(".insight_title") }

          if years_remaining > 0
            p(class: "text-sm text-primary-700") do
              t(".insight", year: @user.expected_graduation_year, per_year: credits_per_year_needed, remaining: credits_needed, years: years_remaining)
            end

            if @user.credits_goal_per_year && credits_per_year_needed > @user.credits_goal_per_year
              p(class: "text-sm text-warning-700 mt-2") do
                t(".goal_warning", goal: @user.credits_goal_per_year)
              end
            end
          else
            p(class: "text-sm text-primary-700") do
              t(".remaining", remaining: credits_needed)
            end
          end
        end
      end

      def format_major(major)
        return t("shared.not_set") unless major.present?

        t("shared.majors.#{major}", default: major)
      end

      def format_enrollment(year, semester)
        return t("shared.not_set") unless year && semester

        t(".enrolled_value", year: year, semester: t("shared.semesters.#{semester}", default: semester))
      end

      def format_year(year)
        year ? year.to_s : t("shared.not_set")
      end

      def format_credits(credits)
        credits ? t("shared.credits", count: credits) : t("shared.not_set")
      end

      def study_plan_complete?
        @user.enrolled_year.present? && @user.expected_graduation_year.present?
      end
    end
  end
end
