require_relative '../test_helper'

class IssueLimitsWarningCpiTest < ActiveSupport::TestCase
  def setup
    User.current = User.find(1)
    @project = Project.find(1)
    @project.enable_module!(:issue_limits_warning)
    Setting.plugin_redmine_issue_limits_warning = RedmineIssueLimitsWarning::Settings::DEFAULTS.dup
    @issue = Issue.create!(project: @project, tracker_id: 1, author_id: 1, status_id: 1,
      subject: 'CPI regression', estimated_hours: 100, done_ratio: 85)
  end

  def teardown
    User.current = nil
  end

  def result(progress, hours, overrides = {})
    @issue.done_ratio = progress
    settings = RedmineIssueLimitsWarning::Settings.effective_for(@project).merge(overrides)
    RedmineIssueLimitsWarning::Checks::TimeBudget.call(@issue, settings: settings, spent_hours: hours)
  end

  def test_progress_aware_boundaries
    with_settings issue_done_ratio: 'issue_field' do
      [[85, 80, :ok], [80, 85, :ok], [60, 80, :danger], [90, 100, :ok],
       [80, 100, :warning], [79, 100, :danger], [89, 100, :warning]].each do |progress, hours, status|
        assert_equal status, result(progress, hours).status, "#{progress}% / #{hours}h"
      end
      assert_in_delta 0.75, result(60, 80).cpi
      assert_in_delta 133.333, result(60, 80).forecast_hours, 0.001
    end
  end

  def test_missing_data_never_appears_green
    with_settings issue_done_ratio: 'issue_field' do
      assert_equal :unknown, result(80, 0).status
      assert_nil result(80, 0).cpi
      @issue.estimated_hours = nil
      assert_equal :missing_estimate, result(80, 10).reason
      assert_equal :unknown, result(80, 10).status
      assert_not result(80, 10).exceeded?
      @issue.estimated_hours = 100
      assert_equal :danger, result(0, 10).status
      assert_nil result(0, 10).forecast_hours
      assert_equal :missing_progress, result(nil, 10).reason
      assert_equal :unknown, result(nil, 10).status
    end
  end

  def test_absolute_limit_is_independent_and_can_exceed_100
    with_settings issue_done_ratio: 'issue_field' do
      assert_not result(100, 110).absolute_limit_reached
      settings = {'absolute_limit_enabled' => '1', 'absolute_limit_threshold' => '120'}
      assert_not result(100, 110, settings).absolute_limit_reached
      reached = result(100, 120, settings)
      assert reached.absolute_limit_reached
      assert_equal 120, reached.absolute_limit_threshold
      assert_equal :danger, reached.status
      assert_equal :warning, reached.cpi_status
    end
  end

  def test_native_status_based_progress
    with_settings issue_done_ratio: 'issue_status' do
      @issue.status.update!(default_done_ratio: 50)
      assert_in_delta 0.5, result(99, 100).cpi
    end
  end

  def test_disabled_module_closed_issue_and_parent_are_not_evaluated
    @project.disable_module!(:issue_limits_warning)
    assert_not result(10, 90).enabled?
    @project.reload.enable_module!(:issue_limits_warning)
    @issue.status = IssueStatus.where(is_closed: true).first!
    assert_not result(10, 90).enabled?
    @issue.status_id = 1
    Issue.create!(project: @project, tracker_id: 1, author_id: 1, subject: 'Child', parent_issue_id: @issue.id)
    @issue.reload
    assert_not result(10, 90).enabled?
  end

  def test_disabled_project_blocks_filter_and_due_date
    IssueLimitsWarningProjectSetting.create!(project: @project, enabled: false)
    @issue.due_date = Date.yesterday
    assert_not result(10, 90).enabled?
    assert_not RedmineIssueLimitsWarning::Checks::DueDate.call(@issue).enabled?
    assert RedmineIssueLimitsWarning::ProjectIssuesFilter.new(@project).counts.values.all?(&:zero?)
  end

  def test_non_finite_values_are_unavailable
    @issue.estimated_hours = Float::INFINITY
    assert_equal :unknown, result(80, 10).status
    @issue.estimated_hours = 100
    assert_equal :unknown, result(80, Float::NAN).status
  end
end
