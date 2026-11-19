# frozen_string_literal: true

class Components::NavBar < Components::Base
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::Request

  register_value_helper :authenticated?

  MENU_ITEM = "flex w-full items-center gap-2 px-4 py-2 text-sm text-gray-700 hover:bg-primary-50 hover:text-primary-900 cursor-pointer"

  def view_template
    nav(class: "bg-primary-800 border-b-4 border-accent-400") do
      div(class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8") do
        div(class: "flex justify-between h-16") do
          div(class: "flex items-center gap-8") do
            render_logo
            render_nav_links
          end
          render_auth_section
        end
      end
    end
  end

  private

  # The main sections, in the order a student uses them: [ label key, icon, path ]
  def sections
    [
      [ ".my_plan", :board, enrollments_path ],
      [ ".catalog", :book, catalog_path ],
      [ ".deadlines", :calendar, deadlines_path ],
      [ ".dashboard", :chart, dashboard_enrollments_path ],
      [ ".documents", :folder, documents_path ]
    ]
  end

  def icon(name, **)
    render Components::Icon.new(name, **)
  end

  def render_logo
    link_to root_path, class: "flex items-center" do
      span(class: "text-xl font-bold tracking-tight text-white") { "Keio Tsushin" }
    end
  end

  def render_nav_links
    div(class: "hidden md:flex md:items-center md:gap-1") do
      sections.each do |key, icon_name, path|
        active = current_section?(path)

        link_to(
          path,
          aria: { current: (active ? "page" : nil) },
          class: "inline-flex items-center gap-1.5 rounded-md px-3 py-2 text-sm font-medium " \
            "#{active ? "bg-primary-950/60 text-white shadow-[inset_0_-2px_0_var(--color-accent-400)]" : "text-primary-100 hover:text-white hover:bg-primary-700"}"
        ) do
          icon(icon_name, class: "size-4 shrink-0 #{active ? "text-accent-300" : "text-primary-300"}")
          plain t(key)
        end
      end
    end
  end

  # The credit dashboard lives under /courses, so it must not also light up the planner
  def current_section?(path)
    current = request.path
    return current == path if path == dashboard_enrollments_path
    return false if current == dashboard_enrollments_path

    current == path || current.start_with?("#{path}/")
  end

  def render_auth_section
    div(class: "flex items-center gap-1") do
      render Components::LocaleSwitcher.new(
        icon: true,
        link_class: "inline-flex items-center rounded-md p-2 text-primary-100 hover:text-white hover:bg-primary-700"
      )

      if authenticated?
        render_account_menu
      else
        link_to(
          t(".sign_in"),
          new_session_path,
          class: "ml-2 inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-primary-900 bg-accent-400 hover:bg-accent-300"
        )
      end
    end
  end

  # A <details> menu, so it opens on click without JavaScript; the dropdown
  # controller only adds closing on outside click and Escape.
  def render_account_menu
    name = Current.user.name.presence || Current.user.email_address

    details(class: "relative group", data: { controller: "dropdown" }) do
      summary(
        title: name,
        aria: { label: t(".account") },
        class: "list-none [&::-webkit-details-marker]:hidden inline-flex items-center rounded-md p-2 cursor-pointer text-primary-100 hover:text-white hover:bg-primary-700 group-open:bg-primary-700 group-open:text-white"
      ) { icon(:account, class: "size-6 shrink-0") }

      div(class: "absolute right-0 z-20 mt-2 w-56 overflow-hidden rounded-lg bg-white py-1 shadow-lg ring-1 ring-primary-100") do
        div(class: "px-4 py-2 border-b border-gray-100") do
          p(class: "truncate text-sm font-semibold text-primary-900") { name }
          p(class: "truncate text-xs text-gray-500") { Current.user.email_address } if Current.user.name.present?
        end

        # On small screens the section links don't fit in the bar, so they live here
        div(class: "md:hidden border-b border-gray-100 py-1") do
          sections.each { |key, icon_name, path| menu_link(t(key), icon_name, path) }
        end

        menu_link(t(".profile"), :user, profile_path)
        menu_link(t(".about"), :info, about_path)

        div(class: "border-t border-gray-100 mt-1 pt-1") do
          button_to(session_path, method: :delete, class: MENU_ITEM, form: { data: { turbo_confirm: t(".sign_out_confirm") } }) do
            icon(:sign_out, class: "size-4 shrink-0 text-gray-400")
            plain t(".sign_out")
          end
        end
      end
    end
  end

  def menu_link(text, icon_name, path)
    link_to(path, class: MENU_ITEM) do
      icon(icon_name, class: "size-4 shrink-0 text-gray-400")
      plain text
    end
  end
end
