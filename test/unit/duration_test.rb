require_relative '../test_helper'
require 'json'

class RilwDurationTest < ActiveSupport::TestCase
  def test_duration_examples_match_redmine
    cases = JSON.parse(File.read(File.expand_path('../duration_cases.json', __dir__)))
    cases.each do |input, expected|
      if expected.nil?
        assert_nil input.to_hours, input.inspect
      else
        assert_equal expected, input.to_hours, input.inspect
      end
    end
  end
end
