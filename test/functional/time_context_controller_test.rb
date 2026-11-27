require_relative '../test_helper'

class RilwTimeContextControllerTest < Redmine::ControllerTest
  tests IssueLimitsWarningTimeContextController
  def setup
    @request.session[:user_id] = 1
    @project = Project.find(1)
    @project.enable_module!(:issue_limits_warning)
    Setting.plugin_redmine_issue_limits_warning = RedmineIssueLimitsWarning::Settings::DEFAULTS.dup
    @issue = Issue.create!(project: @project, tracker_id: 1, author_id: 1,
      subject: 'Entry context', estimated_hours: 10, done_ratio: 90)
    @entry = TimeEntry.create!(project: @project, issue: @issue, user_id: 1, author_id: 1,
      hours: 2, activity: TimeEntryActivity.active.first!, spent_on: Date.today)
  end

  def test_edit_subtracts_original_entry_only_from_original_issue
    get :show, params: {issue_id: @issue.id, time_entry_id: @entry.id}
    assert_response :success
    assert_in_delta 0, response.parsed_body['spent_hours']
    assert_equal 'no-store', response.headers['Cache-Control']
    other = Issue.create!(project: @project, tracker_id: 1, author_id: 1,
      subject: 'Other context', estimated_hours: 20)
    get :show, params: {issue_id: other.id, time_entry_id: @entry.id}
    assert_response :success
    assert_in_delta 0, response.parsed_body['spent_hours']
  end

  def test_create_keeps_all_recorded_hours
    get :show, params: {issue_id: @issue.id}
    assert_response :success
    assert_in_delta 2, response.parsed_body['spent_hours']
  end

  def test_disabled_module_and_private_issue_do_not_expose_data
    @project.disable_module!(:issue_limits_warning)
    get :show, params: {issue_id: @issue.id}
    assert_response :not_found
    @project.reload.enable_module!(:issue_limits_warning)
    @issue.reload.update!(is_private: true)
    @request.session[:user_id] = 4
    get :show, params: {issue_id: @issue.id}
    assert_response :not_found
  end

  def test_invalid_entry_id_is_rejected
    get :show, params: {issue_id: @issue.id, time_entry_id: 999999}
    assert_response :forbidden
  end
end
