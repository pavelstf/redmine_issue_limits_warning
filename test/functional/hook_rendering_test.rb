require_relative '../test_helper'

class RilwIssueHookRenderingTest < Redmine::ControllerTest
  tests IssuesController
  def setup
    @request.session[:user_id] = 1
    @project = Project.find(1)
    @project.enable_module!(:issue_limits_warning)
    Setting.plugin_redmine_issue_limits_warning = RedmineIssueLimitsWarning::Settings::DEFAULTS.dup
    @issue = Issue.create!(project: @project, tracker_id: 1, author_id: 1, subject: 'Rendered CPI',
      estimated_hours: 100, done_ratio: 60)
    TimeEntry.create!(project: @project, issue: @issue, user_id: 1, author_id: 1,
      hours: 80, activity: TimeEntryActivity.active.first!, spent_on: Date.today)
  end

  def test_show_renders_cpi_and_forecast
    get :show, params: {id: @issue.id}
    assert_response :success
    assert_select '.rilw-badge.rilw-time-budget-danger', text: /0.75/
    assert_select '.rilw-badge', text: /133.3/
  end

  def test_module_disabled_removes_badges
    @project.disable_module!(:issue_limits_warning)
    get :show, params: {id: @issue.id}
    assert_response :success
    assert_select '.rilw-badge', count: 0
  end

  def test_standard_list_explains_cpi_and_shows_one_day_overdue
    due_date = User.find(1).today - 1
    @issue.reload.update!(estimated_hours: 40, done_ratio: 20, due_date: due_date)
    @issue.time_entries.first!.update!(hours: 10)

    with_settings issue_done_ratio: 'issue_field', default_language: 'bg', date_format: '%Y-%m-%d', force_default_language_for_loggedin: '1' do
      get :index, params: {project_id: @project.identifier}
      assert_response :success
      assert_select "tr#issue-#{@issue.id}"
      assert_includes response.body, '"time_budget_title":"CPI 0.80 · Завършено 20% · Отчетени 10 от 40 ч (25% от оценката). За този напредък са отчетени повече часове от очакваното."'
      assert_includes response.body, %Q("due_date_title":"Планирана крайна дата: #{due_date} · просрочена с 1 ден")
    end
  end

  def test_tooltip_omits_totals_when_the_user_can_only_see_their_own_time_entries
    @request.session[:user_id] = 2
    Role.find(1).update!(time_entries_visibility: 'own', permissions: %i[view_issues view_time_entries])

    with_settings issue_done_ratio: 'issue_field' do
      get :index, params: {project_id: @project.identifier}
      assert_response :success
      assert_select "tr#issue-#{@issue.id}"
      assert_includes response.body, '"time_budget_title":"CPI 0.75 · 60% complete. More hours have been logged than expected for this progress."'
      assert_not_includes response.body, '80 of 100 h logged'
    end
  end
end

class RilwOverviewHookRenderingTest < Redmine::ControllerTest
  tests ProjectsController
  def setup
    @request.session[:user_id] = 1
    @project = Project.find(1)
    @project.enable_module!(:issue_limits_warning)
    Setting.plugin_redmine_issue_limits_warning = RedmineIssueLimitsWarning::Settings::DEFAULTS.merge('ok_color' => '#123456')
  end

  def test_overview_renders_links_unavailable_count_and_configured_colors
    get :show, params: {id: @project.identifier}
    assert_response :success
    assert_select '.rilw-project-overview[style*="#123456"]'
    assert_select '.rilw-project-overview a[href*="/issue_limits_warning/unknown"]'
  end

  def test_module_disabled_removes_summary
    @project.disable_module!(:issue_limits_warning)
    get :show, params: {id: @project.identifier}
    assert_response :success
    assert_select '.rilw-project-overview', count: 0
  end
end
