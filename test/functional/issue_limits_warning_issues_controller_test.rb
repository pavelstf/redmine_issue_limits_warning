require File.expand_path('../test_helper', __dir__)

class IssueLimitsWarningIssuesControllerTest < ActionController::TestCase
  tests IssueLimitsWarningIssuesController

  fixtures :projects, :users, :roles, :members, :member_roles, :issues,
           :issue_statuses, :trackers, :enumerations

  def setup
    @project = Project.find(1)
    @request.session[:user_id] = 2
  end

  test 'renders a supported filtered issue list' do
    get :index, params: {project_id: @project.identifier, status: 'ok'}
    assert_response :success
    assert_includes response.body, I18n.t(:label_issue_limits_warning)
  end

  test 'returns not found for an unsupported status' do
    get :index, params: {project_id: @project.identifier, status: 'invalid'}
    assert_response :not_found
  end
end
