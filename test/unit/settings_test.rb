require File.expand_path('../test_helper', __dir__)

class RedmineIssueLimitsWarningSettingsTest < ActiveSupport::TestCase
  ProjectDouble = Struct.new(:id)

  test 'normalizes thresholds colors and boolean values' do
    settings = RedmineIssueLimitsWarning::Settings

    assert_equal 80.0, settings.threshold({'warning_threshold' => 'invalid'}, 'warning_threshold')
    assert_equal 75.5, settings.threshold({'warning_threshold' => '75.5'}, 'warning_threshold')
    assert_equal '#16a34a', settings.color({'ok_color' => 'invalid'}, 'ok_color')
    assert settings.truthy?('1')
    refute settings.truthy?('0')
  end

  test 'applies project threshold overrides' do
    project = ProjectDouble.new(42)
    global = RedmineIssueLimitsWarning::Settings::DEFAULTS.merge(
      'project_settings' => {
        '42' => {
          'enabled' => '1',
          'override_thresholds' => '1',
          'warning_threshold' => '70',
          'danger_threshold' => '95',
          'due_date_enabled' => '0'
        }
      }
    )

    RedmineIssueLimitsWarning::Settings.stubs(:global).returns(global)
    effective = RedmineIssueLimitsWarning::Settings.effective_for(project)
    assert_equal '70', effective['warning_threshold']
    assert_equal '95', effective['danger_threshold']
    assert_equal '0', effective['due_date_enabled']
  end

  test 'sanitizes project settings before saving' do
    project = ProjectDouble.new(7)
    saved = nil
    defaults = RedmineIssueLimitsWarning::Settings::DEFAULTS.deep_dup

    RedmineIssueLimitsWarning::Settings.stubs(:global).returns(defaults)
    RedmineIssueLimitsWarning::Settings.stubs(:all_project_settings).returns({})
    Setting.stubs(:plugin_redmine_issue_limits_warning=).with do |value|
      saved = value
    end

    RedmineIssueLimitsWarning::Settings.save_project_settings(
      project,
      {
        'enabled' => '1',
        'override_thresholds' => '1',
        'warning_threshold' => '80,5',
        'danger_threshold' => '-10',
        'due_date_enabled' => '0'
      }
    )

    project_settings = saved.fetch('project_settings').fetch('7')
    assert_equal '1', project_settings['enabled']
    assert_equal '80.5', project_settings['warning_threshold']
    assert_equal '', project_settings['danger_threshold']
    assert_equal '0', project_settings['due_date_enabled']
  end
end
