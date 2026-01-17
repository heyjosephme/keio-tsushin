# frozen_string_literal: true

class Components::Layout < Components::Base
  def initialize(show_nav: true, show_footer: true)
    @show_nav = show_nav
    @show_footer = show_footer
  end

  def view_template(&)
    div(class: "min-h-screen flex flex-col bg-gray-50") do
      render Components::NavBar.new if @show_nav

      main(class: "flex-grow", &)

      render Components::Footer.new if @show_footer
    end
  end
end
