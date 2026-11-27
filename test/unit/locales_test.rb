require_relative '../test_helper'

class RilwLocalesTest < ActiveSupport::TestCase
  def test_locale_keys_and_interpolations_match
    root = File.expand_path('../../config/locales', __dir__)
    en = YAML.safe_load_file(File.join(root, 'en.yml')).fetch('en')
    bg = YAML.safe_load_file(File.join(root, 'bg.yml')).fetch('bg')
    assert_equal en.keys.sort, bg.keys.sort
    en.each do |key, value|
      assert_equal value.to_s.scan(/%\{\w+\}/).sort, bg.fetch(key).to_s.scan(/%\{\w+\}/).sort, key
    end
  end
end
