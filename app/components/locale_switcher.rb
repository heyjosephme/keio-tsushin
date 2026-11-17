# frozen_string_literal: true

# Links that reload the current page in the other language(s). ApplicationController#switch_locale
# reads the ?locale= param and remembers the choice in a cookie.
class Components::LocaleSwitcher < Components::Base
  include Phlex::Rails::Helpers::Request

  NAMES = { en: "English", ja: "日本語" }.freeze

  def view_template
    (I18n.available_locales - [ I18n.locale ]).each do |locale|
      a(href: path_for(locale), lang: locale, class: "text-sm text-gray-600 hover:text-gray-900") { NAMES.fetch(locale) }
    end
  end

  private

  def path_for(locale)
    "#{request.path}?#{request.query_parameters.merge("locale" => locale.to_s).to_query}"
  end
end
