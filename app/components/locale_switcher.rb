# frozen_string_literal: true

# Links that reload the current page in the other language(s). ApplicationController#switch_locale
# reads the ?locale= param and remembers the choice in a cookie.
class Components::LocaleSwitcher < Components::Base
  include Phlex::Rails::Helpers::Request

  NAMES = { en: "English", ja: "日本語" }.freeze

  # link_class: override the link styling, e.g. on the dark navigation bar.
  # icon: show a language icon; the language name stays as a tooltip and for screen readers.
  def initialize(link_class: "text-sm text-gray-600 hover:text-gray-900", icon: false)
    @link_class = link_class
    @icon = icon
  end

  def view_template
    (I18n.available_locales - [ I18n.locale ]).each do |locale|
      a(href: path_for(locale), lang: locale, title: (NAMES.fetch(locale) if @icon), class: @link_class) do
        if @icon
          render Components::Icon.new(:language, class: "size-5 shrink-0")
          span(class: "sr-only") { NAMES.fetch(locale) }
        else
          plain NAMES.fetch(locale)
        end
      end
    end
  end

  private

  def path_for(locale)
    "#{request.path}?#{request.query_parameters.merge("locale" => locale.to_s).to_query}"
  end
end
