# frozen_string_literal: true

module Views
  module Passwords
    class Edit < Views::Base
      include Phlex::Rails::Helpers::Flash
      include Phlex::Rails::Helpers::FormWith

      def initialize(token:)
        @token = token
      end

      def view_template
        div(class: "min-h-screen bg-gradient-to-br from-indigo-50 via-white to-blue-50 flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8") do
          div(class: "max-w-md w-full space-y-8") do
            render_header
            render_flash_messages
            render_form
          end
        end
      end

      private

      def render_header
        div(class: "text-center") do
          h1(class: "text-4xl font-bold text-gray-900 mb-2") { "Update your password" }
          p(class: "text-gray-600") { "Enter your new password below" }
        end
      end

      def render_flash_messages
        if flash[:alert]
          div(class: "rounded-md bg-red-50 p-4") do
            p(class: "text-sm font-medium text-red-800") { flash[:alert] }
          end
        end
      end

      def render_form
        div(class: "bg-white rounded-lg shadow-lg p-8") do
          form_with url: password_path(@token), method: :put, class: "space-y-6" do |form|
            div do
              form.label :password, "New password", class: "block text-sm font-medium text-gray-700"
              form.password_field :password,
                required: true,
                autocomplete: "new-password",
                placeholder: "Enter new password",
                maxlength: 72,
                class: "mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
            end

            div do
              form.label :password_confirmation, "Confirm password", class: "block text-sm font-medium text-gray-700"
              form.password_field :password_confirmation,
                required: true,
                autocomplete: "new-password",
                placeholder: "Repeat new password",
                maxlength: 72,
                class: "mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
            end

            div do
              form.submit "Save",
                class: "w-full inline-flex justify-center rounded-md border border-transparent bg-indigo-600 py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 cursor-pointer"
            end
          end
        end
      end
    end
  end
end
