require_relative '../test_helper'

class RilwGlobalSettingsControllerTest < Redmine::ControllerTest
  tests SettingsController
  def setup
    @request.session[:user_id] = 1
    Setting.plugin_redmine_issue_limits_warning = RedmineIssueLimitsWarning::Settings::DEFAULTS.dup
  end

  def test_global_form_and_real_post_preserve_project_settings
    record = IssueLimitsWarningProjectSetting.create!(project_id: 1, enabled: false)
    get :plugin, params: {id: 'redmine_issue_limits_warning'}
    assert_response :success
    assert_select 'input[name="settings[cpi_warning]"]'
    assert_select 'input[type=checkbox][name="settings[show_ok_issue_list_marker]"]:not([checked])'
    post :plugin, params: {id: 'redmine_issue_limits_warning', settings: {
      'cpi_warning' => '0.95', 'show_ok_issue_list_marker' => '1'}}
    assert_response :redirect
    assert_not record.reload.enabled
    assert_equal '0.95', Setting.plugin_redmine_issue_limits_warning['cpi_warning']
    assert_equal '1', Setting.plugin_redmine_issue_limits_warning['show_ok_issue_list_marker']
  end

  def test_invalid_post_has_errors_and_preserves_saved_values
    post :plugin, params: {id: 'redmine_issue_limits_warning', settings: {'cpi_warning' => '0.5'}}
    assert_response :unprocessable_entity
    assert_equal '0.90', Setting.plugin_redmine_issue_limits_warning['cpi_warning']
  end

  def test_non_admin_cannot_change_settings
    @request.session[:user_id] = 2
    post :plugin, params: {id: 'redmine_issue_limits_warning', settings: {'cpi_warning' => '0.99'}}
    assert_response :forbidden
  end
end
