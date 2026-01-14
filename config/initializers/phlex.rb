# frozen_string_literal: true

# Ensure ActiveSupport's class_attribute is loaded before Phlex
# This fixes eager loading issues in production where Phlex::Rails::Streaming
# tries to use class_attribute before ActiveSupport is fully loaded
require "active_support/core_ext/class/attribute"

module Views
end

module Components
  extend Phlex::Kit
end

Rails.autoloaders.main.push_dir(
  Rails.root.join("app/views"), namespace: Views
)

Rails.autoloaders.main.push_dir(
  Rails.root.join("app/components"), namespace: Components
)
