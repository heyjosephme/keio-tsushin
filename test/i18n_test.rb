require "test_helper"

class I18nTest < ActiveSupport::TestCase
  test "en.yml and ja.yml define the same keys" do
    en, ja = %w[en ja].map { |locale| keys(YAML.load_file(Rails.root.join("config/locales/#{locale}.yml")).fetch(locale)) }

    assert_empty en - ja, "missing from ja.yml"
    assert_empty ja - en, "missing from en.yml"
  end

  private

  # Flattened key paths; plural forms (one/other) count as one key
  def keys(hash, prefix = nil)
    hash.flat_map do |key, value|
      path = [ prefix, key ].compact.join(".")
      next [ path ] unless value.is_a?(Hash)
      next [ path ] if (value.keys - %w[zero one two few many other]).empty?

      keys(value, path)
    end.sort
  end
end
