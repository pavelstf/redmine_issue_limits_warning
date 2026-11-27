require_relative '../test_helper'

class IssueLimitsWarningProjectIssuesFilterTest < ActiveSupport::TestCase
  def setup
    User.current = User.find(1)
    @project = Project.find(1)
    @project.enable_module!(:issue_limits_warning)
    Setting.plugin_redmine_issue_limits_warning = RedmineIssueLimitsWarning::Settings::DEFAULTS.deep_dup
  end

  def teardown
    User.current = nil
  end

  def test_open_leaf_without_estimate_is_included
    issue = create_issue
    assert_includes missing_estimate_ids, issue.id
  end

  def test_leaf_with_zero_estimate_is_included
    issue = create_issue(estimated_hours: 0)
    assert_includes missing_estimate_ids, issue.id
  end

  def test_parent_with_open_child_is_excluded
    parent = create_issue
    child = create_issue(parent_issue_id: parent.id)
    assert_not_includes missing_estimate_ids, parent.id
    assert_includes missing_estimate_ids, child.id
  end

  def test_parent_with_only_closed_child_is_excluded
    parent = create_issue
    child = create_issue(parent_issue_id: parent.id, status: IssueStatus.where(is_closed: true).first!)
    assert child.closed?
    assert_not parent.reload.leaf?
    assert_not_includes missing_estimate_ids, parent.id
    assert_not_includes missing_estimate_ids, child.id
  end

  def test_parent_with_hidden_child_is_excluded_for_restricted_user
    parent = create_issue
    child = create_issue(parent_issue_id: parent.id, is_private: true)
    User.current = User.anonymous
    assert parent.reload.visible?
    assert_not child.visible?
    assert_not_includes missing_estimate_ids, parent.id
    assert_not_includes missing_estimate_ids, child.id
  end

  def test_parent_with_child_in_another_project_is_excluded
    with_settings cross_project_subtasks: 'system' do
      parent = create_issue
      child = create_issue(parent_issue_id: parent.id, project: Project.find(2))
      assert_equal parent.id, child.reload.parent_id
      assert_not parent.reload.leaf?
      assert_not_includes missing_estimate_ids, parent.id
      assert_not_includes missing_estimate_ids, child.id
    end
  end

  def test_closed_estimated_hidden_and_other_project_leaves_are_excluded
    closed = create_issue(status: IssueStatus.where(is_closed: true).first!)
    estimated = create_issue(estimated_hours: 2)
    hidden = create_issue(is_private: true)
    elsewhere = create_issue(project: Project.find(2))
    visible = create_issue
    User.current = User.anonymous
    assert visible.visible?
    assert_not hidden.visible?
    ids = missing_estimate_ids
    [closed, estimated, hidden, elsewhere].each { |issue| assert_not_includes ids, issue.id }
    assert_includes ids, visible.id
  end

  def test_summary_count_and_filtered_list_agree_for_restricted_user
    parent = create_issue
    create_issue(parent_issue_id: parent.id, is_private: true)
    leaf = create_issue
    User.current = User.anonymous
    filter = RedmineIssueLimitsWarning::ProjectIssuesFilter.new(@project)
    ids = filter.issue_ids_for('without_estimate').sort
    assert_includes ids, leaf.id
    assert_not_includes ids, parent.id
    assert_equal ids, filter.issues_for('without_estimate').pluck(:id).sort
    assert_equal ids.size, RedmineIssueLimitsWarning::ProjectSummary.new(@project).counts[:without_estimate]
  end

  private

  def create_issue(attributes = {})
    Issue.create!({project: @project, tracker_id: 1, author_id: 1,
                   status_id: 1, subject: 'Leaf regression', estimated_hours: nil}.merge(attributes))
  end

  def missing_estimate_ids
    RedmineIssueLimitsWarning::ProjectIssuesFilter.new(@project).issue_ids_for('without_estimate')
  end
end
