require_relative '../test_helper'
require File.expand_path('../../db/migrate/001_create_rilw_project_settings', __dir__)

class IssueLimitsWarningSettingsTest < ActiveSupport::TestCase
  def setup
    User.current = User.find(1)
    Setting.plugin_redmine_issue_limits_warning = RedmineIssueLimitsWarning::Settings::DEFAULTS.dup
  end

  def teardown
    User.current = nil
  end

  def test_project_rows_are_independent_and_survive_global_save
    settings = RedmineIssueLimitsWarning::Settings
    settings.save_project_settings(Project.find(1), {'enabled' => false, 'cpi_warning' => '0,95'})
    settings.save_project_settings(Project.find(2), {'cpi_danger' => '0.7'})
    _, errors = settings.save_global('cpi_warning' => '0.92')
    assert_empty errors
    assert_equal '0', settings.project_settings_for(Project.find(1))['enabled']
    assert_equal '0.95', settings.project_settings_for(Project.find(1))['cpi_warning']
    assert_equal '0.7', settings.project_settings_for(Project.find(2))['cpi_danger']
  end

  def test_validation_and_optimistic_locking
    record = IssueLimitsWarningProjectSetting.create!(project_id: 1)
    stale = IssueLimitsWarningProjectSetting.find(record.id)
    record.update!(cpi_warning: '0.95')
    assert_raises(ActiveRecord::StaleObjectError) { stale.update!(cpi_warning: '0.99') }
    %w[0.9junk NaN Infinity -1 0 1.5].each do |invalid|
      assert_not IssueLimitsWarningProjectSetting.new(project_id: 2, cpi_warning: invalid).valid?, invalid
    end
    assert_not IssueLimitsWarningProjectSetting.new(project_id: 2, cpi_warning: 0.7, cpi_danger: 0.8).valid?
    assert IssueLimitsWarningProjectSetting.new(project_id: 2, absolute_limit_threshold: 150).valid?
    assert_not IssueLimitsWarningProjectSetting.new(project_id: 1).valid?
  end

  def test_global_validation_does_not_write_on_failure
    before = Setting.plugin_redmine_issue_limits_warning.deep_dup
    [{'cpi_warning' => '0.7'}, {'cpi_danger' => 'abc'}, {'ok_color' => 'red'},
     {'absolute_limit_threshold' => 'NaN'}].each do |invalid|
      _, errors = RedmineIssueLimitsWarning::Settings.save_global(invalid)
      assert errors.any?
      assert_equal before, Setting.plugin_redmine_issue_limits_warning
    end
  end

  def test_two_first_time_forms_do_not_overwrite_each_other
    settings = RedmineIssueLimitsWarning::Settings
    settings.save_project_settings(Project.find(1), {'new_record' => '1', 'cpi_warning' => '0.95'})
    assert_raises(ActiveRecord::StaleObjectError) do
      settings.save_project_settings(Project.find(1), {'new_record' => '1', 'cpi_warning' => '0.99'})
    end
    assert_in_delta 0.95, IssueLimitsWarningProjectSetting.find_by!(project_id: 1).cpi_warning.to_f
  end

  def test_database_cascades_deleted_project_settings
    project = Project.create!(name: 'Temporary CPI project', identifier: 'temporary-cpi-project')
    record = IssueLimitsWarningProjectSetting.create!(project: project)
    project.delete
    assert_not IssueLimitsWarningProjectSetting.exists?(record.id)
  end

  def test_decimal_comma_global_values_are_normalized_for_javascript_context
    values, errors = RedmineIssueLimitsWarning::Settings.save_global('cpi_warning' => '0,95')
    assert_empty errors
    assert_equal '0.95', values['cpi_warning']
    assert_equal '0.95', RedmineIssueLimitsWarning::Settings.global['cpi_warning']
  end

  def test_legacy_copy_is_repeatable_and_does_not_delete_or_reinterpret_old_thresholds
    legacy = {'project_settings' => {'1' => {'enabled' => '0', 'override_thresholds' => true,
      'warning_threshold' => '80', 'danger_threshold' => '150', 'due_date_enabled' => '0'}}}
    Setting.plugin_redmine_issue_limits_warning = ActionController::Parameters.new(legacy).permit!.to_h
    migration = CreateRilwProjectSettings.new
    migration.up
    migrated = IssueLimitsWarningProjectSetting.find_by!(project_id: 1)
    assert_not migrated.enabled
    assert_not migrated.due_date_enabled
    assert migrated.override_thresholds
    assert_in_delta 0.9, migrated.cpi_warning.to_f
    assert_in_delta 0.8, migrated.cpi_danger.to_f
    assert_in_delta 150, migrated.absolute_limit_threshold.to_f
    assert_not migrated.absolute_limit_enabled
    migrated.update!(cpi_warning: 0.99)
    migration.up
    assert_in_delta 0.99, migrated.reload.cpi_warning.to_f
    assert_equal legacy['project_settings'], Setting.plugin_redmine_issue_limits_warning['project_settings']
  end
end
