require_relative '../test_helper'

class RilwProjectControllerTest < Redmine::ControllerTest
  tests IssueLimitsWarningProjectSettingsController
  def setup
    @request.session[:user_id] = 1
    @project = Project.find(1)
    @project.enable_module!(:issue_limits_warning)
  end

  def test_routes_do_not_capture_edit_as_a_category
    assert_routing({method: 'get', path: '/projects/ecookbook/issue_limits_warning/edit'},
      controller: 'issue_limits_warning_project_settings', action: 'edit', project_id: 'ecookbook')
    assert_routing({method: 'get', path: '/projects/ecookbook/issue_limits_warning/danger'},
      controller: 'issue_limits_warning_issues', action: 'index', project_id: 'ecookbook', status: 'danger')
  end

  def test_old_edit_url_redirects_to_native_settings_tab
    get :edit, params: {project_id: 'ecookbook'}
    assert_redirected_to settings_project_path(@project, tab: 'issue_limits_warning')
  end

  def test_invalid_and_stale_saves
    record = IssueLimitsWarningProjectSetting.create!(project: @project)
    put :update, params: {project_id: 1, issue_limits_warning: {cpi_danger: '0.99'}}
    assert_response :unprocessable_entity
    assert_select '#tab-issue_limits_warning.selected'
    assert_select '#tab-content-issue_limits_warning input[name="issue_limits_warning[cpi_danger]"][value="0.99"]'
    record.update!(cpi_warning: '0.99')
    put :update, params: {project_id: 1, issue_limits_warning: {cpi_warning: '0.95', lock_version: 0}}
    assert_response :conflict
  end

  def test_module_disabled_denies_settings
    @project.disable_module!(:issue_limits_warning)
    get :edit, params: {project_id: 1}
    assert_response :forbidden
    assert_no_difference 'IssueLimitsWarningProjectSetting.count' do
      put :update, params: {project_id: 1, issue_limits_warning: {enabled: '0'}}
    end
    assert_response :forbidden
  end

  def test_first_save_conflict_from_model_or_database_reloads_winner
    winner = IssueLimitsWarningProjectSetting.create!(project: @project, cpi_warning: '0.97')
    duplicate = IssueLimitsWarningProjectSetting.new(project: @project)
    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:project_id, :taken)

    [ActiveRecord::RecordInvalid.new(duplicate), ActiveRecord::RecordNotUnique.new].each do |error|
      RedmineIssueLimitsWarning::Settings.expects(:save_project_settings).raises(error)
      put :update, params: {project_id: @project.id, issue_limits_warning: {new_record: '1', cpi_warning: '0.95'}}
      assert_response :conflict
      assert_select 'input[name="issue_limits_warning[cpi_warning]"][value="0.97"]'
      assert_equal BigDecimal('0.97'), winner.reload.cpi_warning
    end
  end
end
