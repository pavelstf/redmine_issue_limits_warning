require_relative '../test_helper'

class RilwProjectSettingsTabTest < Redmine::IntegrationTest
  def setup
    @project = Project.find(1)
    @project.enable_module!(:issue_limits_warning)
  end

  def test_administrator_can_open_and_save_the_native_tab
    log_user('admin', 'admin')
    assert_can_save_from_tab
  end

  def test_edit_project_permission_is_sufficient_even_when_warnings_are_off
    Role.find(1).update!(permissions: [:view_project, :edit_project])
    IssueLimitsWarningProjectSetting.create!(project: @project, enabled: false)
    log_user('jsmith', 'jsmith')
    assert_can_save_from_tab
  end

  def test_settings_access_without_edit_project_does_not_grant_tab_or_write_access
    Role.find(2).update!(permissions: [:view_project, :manage_members])
    record = IssueLimitsWarningProjectSetting.create!(project: @project)
    log_user('dlopper', 'foo')

    get settings_project_path(@project, tab: 'issue_limits_warning')
    assert_response :success
    assert_select '#tab-members'
    assert_select '#tab-issue_limits_warning, #issue-limits-warning-settings-form', count: 0
    assert_select '#main-menu a.issue-limits-warning', count: 0

    get edit_project_issue_limits_warning_path(@project)
    assert_response :forbidden
    put project_issue_limits_warning_path(@project), params: {issue_limits_warning: {enabled: '0'}}
    assert_response :forbidden
    assert record.reload.enabled?
  end

  def test_disabled_module_hides_tab_even_for_an_administrator
    @project.disable_module!(:issue_limits_warning)
    log_user('admin', 'admin')
    get settings_project_path(@project, tab: 'issue_limits_warning')
    assert_response :success
    assert_select '#tab-issue_limits_warning, #issue-limits-warning-settings-form', count: 0
    assert_select 'input[name="project[enabled_module_names][]"][value="issue_limits_warning"]', count: 1
  end

  private

  def assert_can_save_from_tab
    get settings_project_path(@project)
    assert_response :success
    assert_select '#tab-issue_limits_warning[href=?]', settings_project_path(@project, tab: 'issue_limits_warning')

    get settings_project_path(@project, tab: 'issue_limits_warning')
    assert_response :success
    assert_select '#main-menu a.issue-limits-warning', count: 0
    assert_select '#tab-issue_limits_warning.selected'
    assert_select '#tab-content-issue_limits_warning #issue-limits-warning-settings-form' do
      assert_select 'input[name="issue_limits_warning[lock_version]"]'
    end
    put project_issue_limits_warning_path(@project), params: {issue_limits_warning: {
      enabled: '1', override_thresholds: '1', cpi_warning: '0.95', cpi_danger: '0.75', lock_version: '0'}}
    assert_redirected_to settings_project_path(@project, tab: 'issue_limits_warning')
    follow_redirect!
    assert_response :success
    assert_select '#tab-issue_limits_warning.selected'
    assert_select 'input[name="issue_limits_warning[cpi_warning]"][value="0.95"]'
    assert IssueLimitsWarningProjectSetting.find_by!(project: @project).enabled?
  end
end
