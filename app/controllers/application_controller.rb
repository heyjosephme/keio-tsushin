class ApplicationController < ActionController::Base
  around_action :switch_locale
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  # Language, in order of priority: a ?locale= param (remembered in a cookie),
  # the cookie, the browser's Accept-Language header, then the default (English).
  def switch_locale(&action)
    I18n.with_locale(requested_locale, &action)
  end

  def requested_locale
    if (locale = available_locale(params[:locale]))
      cookies.permanent[:locale] = locale
      return locale
    end

    available_locale(cookies[:locale]) || browser_locale || I18n.default_locale
  end

  def available_locale(value)
    value.to_s if I18n.available_locales.map(&:to_s).include?(value.to_s)
  end

  def browser_locale
    request.headers["Accept-Language"].to_s.split(",").each do |entry|
      locale = available_locale(entry.strip[/\A[a-zA-Z]+/].to_s.downcase)
      return locale if locale
    end
    nil
  end
end
