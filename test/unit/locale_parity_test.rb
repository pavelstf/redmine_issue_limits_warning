require File.expand_path('../test_helper', __dir__)

class RedmineIssueLimitsWarningLocaleParityTest < ActiveSupport::TestCase
  LOCALE_DIR = File.expand_path('../../config/locales', __dir__)

  test 'English and Bulgarian locales have matching keys and placeholders' do
    english = YAML.load_file(File.join(LOCALE_DIR, 'en.yml')).fetch('en')
    bulgarian = YAML.load_file(File.join(LOCALE_DIR, 'bg.yml')).fetch('bg')

    assert_equal flatten_keys(english), flatten_keys(bulgarian)

    flatten_values(english).each do |key, value|
      assert_equal placeholders(value), placeholders(flatten_values(bulgarian).fetch(key)), key
    end
  end

  private

  def flatten_keys(hash, prefix = nil)
    hash.flat_map do |key, value|
      path = [prefix, key].compact.join('.')
      value.is_a?(Hash) ? flatten_keys(value, path) : path
    end.sort
  end

  def flatten_values(hash, prefix = nil, result = {})
    hash.each do |key, value|
      path = [prefix, key].compact.join('.')
      value.is_a?(Hash) ? flatten_values(value, path, result) : result[path] = value.to_s
    end
    result
  end

  def placeholders(value)
    value.scan(/%\{[^}]+\}/).sort
  end
end
