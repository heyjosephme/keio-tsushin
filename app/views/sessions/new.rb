# frozen_string_literal: true

module Views
  module Sessions
    class New < Views::Base
      include Phlex::Rails::Helpers::Flash
      include Phlex::Rails::Helpers::LinkTo
      include Phlex::Rails::Helpers::FormWith

      def view_template
        div(class: "min-h-screen bg-gradient-to-br from-indigo-50 via-white to-blue-50 flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8") do
          div(class: "max-w-md w-full space-y-8") do
            render_header
            render_flash_messages
            render_form
            render_registration_notice
          end
        end
      end

      private

      def render_header
        div(class: "text-center") do
          h1(class: "text-4xl font-bold text-gray-900 mb-2") { "Sign in" }
          p(class: "text-gray-600") { "Keio Tsushin Credit Management" }
        end
      end

      def render_flash_messages
        if flash[:notice]
          div(class: "rounded-md bg-green-50 p-4") do
            p(class: "text-sm font-medium text-green-800") { flash[:notice] }
          end
        end

        if flash[:alert]
          div(class: "rounded-md bg-red-50 p-4") do
            p(class: "text-sm font-medium text-red-800") { flash[:alert] }
          end
        end
      end

      def render_form
        div(class: "bg-white rounded-lg shadow-lg p-8") do
          form_with url: session_path, class: "space-y-6" do |form|
            div do
              form.label :email_address, "Email address", class: "block text-sm font-medium text-gray-700"
              form.email_field :email_address,
                required: true,
                autofocus: true,
                autocomplete: "username",
                placeholder: "Enter your email address",
                class: "mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
            end

            div do
              form.label :password, "Password", class: "block text-sm font-medium text-gray-700"
              form.password_field :password,
                required: true,
                autocomplete: "current-password",
                placeholder: "Enter your password",
                maxlength: 72,
                class: "mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
            end

            div(class: "flex items-center justify-between") do
              form.submit "Sign in",
                class: "w-full sm:w-auto inline-flex justify-center rounded-md border border-transparent bg-indigo-600 py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 cursor-pointer"

              link_to "Forgot password?",
                new_password_path,
                class: "text-sm text-indigo-600 hover:text-indigo-500"
            end
          end
        end
      end

      def render_registration_notice
        div(class: "bg-amber-50 border border-amber-200 rounded-lg p-4") do
          h3(class: "text-sm font-medium text-amber-800 mb-2") { "Registration Not Available" }
          p(class: "text-sm text-amber-700 mb-3") do
            "This is a personal project. Public registration is not currently available."
          end

          div(class: "text-sm text-amber-700 space-y-2") do
            div do
              span(class: "font-medium") { "For demo/testing: " }
              span { "student@example.com / password123" }
            end

            div do
              span(class: "font-medium") { "Need an account? " }
              span { "Please contact the administrator." }
            end
          end
        end
      end
    end
  end
end
