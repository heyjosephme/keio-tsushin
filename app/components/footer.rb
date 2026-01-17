# frozen_string_literal: true

class Components::Footer < Components::Base
  include Phlex::Rails::Helpers::LinkTo

  def view_template
    footer(class: "bg-white border-t border-gray-200") do
      div(class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8") do
        div(class: "md:flex md:justify-between") do
          render_brand_section
          render_links_section
        end

        render_copyright
      end
    end
  end

  private

  def render_brand_section
    div(class: "mb-6 md:mb-0") do
      span(class: "text-lg font-bold text-indigo-600") { "Keio Tsushin" }
      p(class: "mt-2 text-sm text-gray-500 max-w-xs") do
        "A personal credit management system for Keio University distance learning students."
      end
    end
  end

  def render_links_section
    div(class: "grid grid-cols-2 gap-8 sm:grid-cols-3") do
      render_link_group("Navigation", [
        ["Home", root_path],
        ["Deadlines", deadlines_path],
        ["Courses", enrollments_path],
        ["Dashboard", dashboard_enrollments_path]
      ])

      render_link_group("Resources", [
        ["About", about_path],
        ["Keio Tsushin", "https://www.tsushin.keio.ac.jp/"]
      ])
    end
  end

  def render_link_group(title, links)
    div do
      h3(class: "text-sm font-semibold text-gray-900 uppercase tracking-wider") { title }
      ul(class: "mt-4 space-y-2") do
        links.each do |text, path|
          li do
            link_to(
              text,
              path,
              class: "text-sm text-gray-500 hover:text-gray-900",
              target: path.start_with?("http") ? "_blank" : nil
            )
          end
        end
      end
    end
  end

  def render_copyright
    div(class: "mt-8 pt-8 border-t border-gray-200") do
      p(class: "text-sm text-gray-400 text-center") do
        "Built for Keio University Distance Learning Students"
      end
    end
  end
end
