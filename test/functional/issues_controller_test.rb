require_relative '../test_helper'

class RilwIssuesControllerTest < Redmine::ControllerTest
  tests IssueLimitsWarningIssuesController
  def setup
    @request.session[:user_id] = 1
    @project = Project.find(1)
    @project.enable_module!(:issue_limits_warning)
    Setting.plugin_redmine_issue_limits_warning = RedmineIssueLimitsWarning::Settings::DEFAULTS.dup
    @issue = Issue.create!(project: @project, tracker_id: 1, author_id: 1,
      subject: '<script>subject</script>', estimated_hours: 100, done_ratio: 10)
    TimeEntry.create!(project: @project, issue: @issue, user_id: 1, author_id: 1,
      hours: 50, activity: TimeEntryActivity.active.first!, spent_on: Date.today)
  end

  def test_filtered_list_renders_status_data_and_escapes_subjects
    get :index, params: {project_id: @project.identifier, status: 'danger'}
    assert_response :success
    assert_select "tr#issue-#{@issue.id}"
    assert_select "tr#issue-#{@issue.id} td.rilw-cpi", text: '0.20'
    assert_includes response.body, 'time_budget_status'
    assert_includes response.body, 'CPI 0.20 · 10% complete · 50 of 100 h logged (50% of estimate). More hours have been logged than expected for this progress.'
    assert_not_includes response.body, '<script>subject</script>'
  end

  def test_absolute_limit_title_uses_project_threshold_even_with_normal_cpi
    @issue.reload.update!(estimated_hours: 40, done_ratio: 100)
    @issue.time_entries.first!.update!(hours: 42.5)
    Setting.plugin_redmine_issue_limits_warning = RedmineIssueLimitsWarning::Settings::DEFAULTS.merge(
      'absolute_limit_enabled' => '1', 'absolute_limit_threshold' => '120')
    IssueLimitsWarningProjectSetting.create!(project: @project, override_thresholds: true,
      absolute_limit_enabled: true, absolute_limit_threshold: '106.25')

    with_settings issue_done_ratio: 'issue_field' do
      get :index, params: {project_id: @project.id, status: 'danger'}
      assert_response :success
      assert_select "tr#issue-#{@issue.id}"
      assert_includes response.body, 'CPI 0.94 · 100% complete · 42.5 of 40 h logged (106.25% of estimate). Normal time efficiency. The absolute limit of 106.25% has been reached.'
      assert_not_includes response.body, 'The absolute limit of 120% has been reached.'
      assert_not_includes response.body, 'More hours have been logged than expected for this progress.'
    end
  end

  def test_zero_progress_has_its_own_explanation
    @issue.reload.update!(done_ratio: 0)
    with_settings issue_done_ratio: 'issue_field' do
      get :index, params: {project_id: @project.id, status: 'danger'}
      assert_response :success
      assert_includes response.body, 'CPI 0.00 · 0% complete · 50 of 100 h logged (50% of estimate). Hours have been logged at 0% completion.'
    end
  end

  def test_global_limit_shows_the_configured_precision_with_cpi_disabled
    @issue.reload.update!(estimated_hours: 40)
    Setting.plugin_redmine_issue_limits_warning = RedmineIssueLimitsWarning::Settings::DEFAULTS.merge(
      'time_budget_enabled' => '0', 'absolute_limit_enabled' => '1', 'absolute_limit_threshold' => '120.125')

    with_settings issue_done_ratio: 'issue_field' do
      get :index, params: {project_id: @project.id, status: 'danger'}
      assert_response :success
      assert_includes response.body, '"time_budget_title":"10% complete · 50 of 40 h logged (125% of estimate). The absolute limit of 120.125% has been reached."'
    end
  end

  def test_green_marker_is_optional_and_overdue_hint_is_independent
    due_date = User.find(1).today - 3
    @issue.reload.update_columns(done_ratio: 60, due_date: due_date)
    title = %Q("due_date_title":"Планирана крайна дата: #{due_date} · просрочена с 3 дни")
    with_settings issue_done_ratio: 'issue_field', default_language: 'bg', date_format: '%Y-%m-%d', force_default_language_for_loggedin: '1' do
      params = {project_id: @project.id, status: 'overdue'}
      get :index, params: params
      assert_response :success
      assert_includes response.body, title
      assert_not_includes response.body, 'Нормална ефективност по часове'

      Setting.plugin_redmine_issue_limits_warning = RedmineIssueLimitsWarning::Settings::DEFAULTS.merge(
        'show_ok_issue_list_marker' => '1')
      get :index, params: params
      assert_response :success
      assert_includes response.body, 'Нормална ефективност по часове'
      assert_includes response.body, title
    end
  end

  def test_module_off_blocks_direct_list_url
    @project.disable_module!(:issue_limits_warning)
    get :index, params: {project_id: 1, status: 'danger'}
    assert_response :not_found
  end

  def test_filtered_sorting_before_pagination
    @project.issues.where.not(id: @issue.id).update_all(due_date: nil)
    @issue.reload.update!(due_date: Date.yesterday)
    higher_cpi = Issue.create!(project: @project, tracker_id: 1, author_id: 1,
      subject: 'Higher CPI at lower completion', estimated_hours: 100, done_ratio: 5, due_date: Date.yesterday)
    entry = @issue.time_entries.first!.dup
    entry.update!(issue: higher_cpi, hours: 5)
    unavailable = Issue.create!(project: @project, tracker_id: 1, author_id: 1,
      subject: 'Unavailable CPI', estimated_hours: 100, done_ratio: 20, due_date: Date.yesterday)
    params = {project_id: @project.identifier, status: 'overdue', per_page: 1}

    with_settings issue_done_ratio: 'issue_field', per_page_options: '1,25' do
      get :index, params: params.merge(sort: 'cpi:asc')
      assert_select 'tr.issue', count: 1 do |rows|
        assert_equal "issue-#{@issue.id}", rows.first['id'], rows.first.text
      end
      assert_select '.pagination a[href*="sort=cpi%3Aasc"]'

      get :index, params: params.merge(sort: 'cpi:desc', page: 2)
      assert_select "tr#issue-#{@issue.id}"
      assert_select 'th[aria-sort=descending] a[href*="sort=cpi%3Aasc"]' do |links|
        assert_not_includes Rack::Utils.parse_query(URI.parse(links.first['href']).query), 'page'
      end

      get :index, params: params.merge(sort: 'cpi:desc', page: 3)
      assert_select "tr#issue-#{unavailable.id}"

      get :index, params: params.merge(sort: 'done_ratio:asc')
      assert_select "tr#issue-#{higher_cpi.id}"

      get :index, params: params.merge(sort: 'done_ratio:desc')
      assert_select "tr#issue-#{unavailable.id}"
    end
  end

  def test_invalid_status
    assert_raises(ActionController::UrlGenerationError) do
      get :index, params: {project_id: 1, status: 'invalid'}
    end
  end

  def test_overdue_pagination_uses_grouped_hours_even_without_cpi
    settings = RedmineIssueLimitsWarning::Settings::DEFAULTS.merge('time_budget_enabled' => '0')
    Setting.plugin_redmine_issue_limits_warning = settings
    parent = @issue
    Issue.create!(project: @project, tracker_id: 1, author_id: 1, parent_issue_id: parent.id,
      subject: 'Child without overdue date')
    parent.reload.update_columns(due_date: Date.yesterday)
    template = parent.attributes.except('id').merge('parent_id' => nil, 'root_id' => nil, 'lft' => 1, 'rgt' => 2)
    Issue.insert_all!(100.times.map { template.merge('subject' => 'Overdue test leaf') })
    latest = Issue.where(subject: 'Overdue test leaf').maximum(:id)
    hours = TimeEntry.where(issue_id: parent.id).sum(:hours)

    with_settings per_page_options: '25,100' do
      [25, 100].each do |per_page|
        sums = []
        subscriber = lambda do |_name, _start, _finish, _id, payload|
          sql = payload[:sql]
          sums << sql if sql.match?(/SUM\([^)]*hours/i) && sql.match?(/time_entries/i)
        end
        ActiveSupport::Notifications.subscribed(subscriber, 'sql.active_record') do
          get :index, params: {project_id: @project.id, status: 'overdue', per_page: per_page}
        end
        assert_response :success
        assert_select 'tr.issue', count: per_page
        assert_select "tr#issue-#{latest} td.spent_hours", text: '0.0'
        assert_operator sums.length, :<=, 2
        assert sums.all? { |sql| sql.match?(/GROUP BY/i) }, sums.join("\n")
      end
      get :index, params: {project_id: @project.id, status: 'overdue', per_page: 100, page: 2}
      assert_response :success
      assert_select "tr#issue-#{parent.id} td.spent_hours", text: hours.to_f.to_s
    end
  end
end
