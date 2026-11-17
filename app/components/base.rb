# frozen_string_literal: true

class Components::Base < Phlex::HTML
  # Include any helpers you want to be available across all components
  include Phlex::Rails::Helpers::Routes
  # t(".key") looks up views.<resource>.<action>.key or components.<name>.key; l formats dates
  include Phlex::Rails::Helpers::Translate
  include Phlex::Rails::Helpers::L

  if Rails.env.development?
    def before_template
      comment { "Before #{self.class.name}" }
      super
    end
  end
end
