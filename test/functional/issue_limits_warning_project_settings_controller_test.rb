require File.expand_path('../test_helper', __dir__)

class IssueLimitsWarningProjectSettingsControllerTest < ActionController::TestCase
  tests IssueLimitsWarningProjectSettingsController

  fixtures :projects, :users, :roles, :members, :member_roles, :enabled_modules

  def setup
    @project = Project.find(1)
    @request.session[:user_id] = 2
    Role.find(1).add_permission! :manage_issue_limits_warning
    @project.enabled_module_names = @project.enabled_module_names | ['issue_limits_warning']
  end

  test 'renders edit for an authorized project member' do
    get :edit, params: {project_id: @project.identifier}
    assert_response :success
    assert_template :edit
  end

  test 'updates sanitized project settings' do
    put :update, params: {
      project_id: @project.identifier,
      issue_limits_warning: {
        enabled: '1',
        override_thresholds: '1',
        warning_threshold: '75',
        danger_threshold: '100',
        due_date_enabled: '1'
      }
    }

    assert_redirected_to edit_project_issue_limits_warning_path(@project)
    saved = RedmineIssueLimitsWarning::Settings.project_settings_for(@project)
    assert_equal '1', saved['enabled']
    assert_equal '75.0', saved['warning_threshold']
    assert_equal '100.0', saved['danger_threshold']
  end
end
