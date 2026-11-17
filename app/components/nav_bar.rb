# frozen_string_literal: true

class Components::NavBar < Components::Base
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ButtonTo

  register_value_helper :authenticated?

  def view_template
    nav(class: "bg-white shadow-sm") do
      div(class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8") do
        div(class: "flex justify-between h-16") do
          render_logo
          render_nav_links
          render_auth_section
        end
      end
    end
  end

  private

  def render_logo
    div(class: "flex items-center") do
      link_to root_path, class: "flex items-center" do
        span(class: "text-xl font-bold text-indigo-600") { "Keio Tsushin" }
      end
    end
  end

  def render_nav_links
    div(class: "hidden sm:flex sm:items-center sm:space-x-4") do
      nav_link(t(".deadlines"), deadlines_path)
      nav_link(t(".catalog"), catalog_path)
      nav_link(t(".my_plan"), enrollments_path)
      nav_link(t(".dashboard"), dashboard_enrollments_path)
      nav_link(t(".documents"), documents_path)
      nav_link(t(".about"), about_path)
    end
  end

  def render_auth_section
    div(class: "flex items-center gap-4") do
      render Components::LocaleSwitcher.new

      if authenticated?
        link_to(
          Current.user.name.presence || Current.user.email_address,
          profile_path,
          class: "hidden sm:block text-sm text-gray-600 hover:text-gray-900"
        )
        button_to(
          t(".sign_out"),
          session_path,
          method: :delete,
          class: "text-sm text-gray-600 hover:text-gray-900",
          form: { data: { turbo_confirm: t(".sign_out_confirm") } }
        )
      else
        link_to(
          t(".sign_in"),
          new_session_path,
          class: "inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
        )
      end
    end
  end

  def nav_link(text, path)
    link_to(
      text,
      path,
      class: "text-gray-600 hover:text-gray-900 px-3 py-2 text-sm font-medium"
    )
  end
end
