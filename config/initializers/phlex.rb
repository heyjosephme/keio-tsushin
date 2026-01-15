# frozen_string_literal: true

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

# FIXME: workaround for https://github.com/yippee-fun/phlex-rails/issues/323
Phlex::Rails::Loader.tap do |loader|
  gem_path = Gem.loaded_specs["phlex-rails"].full_gem_path
  loader.do_not_eager_load(File.join(gem_path, "lib/phlex/rails/streaming.rb"))
end
