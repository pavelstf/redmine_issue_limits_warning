require File.expand_path('../test_helper', __dir__)

class RedmineIssueLimitsWarningProjectIssuesFilterTest < ActiveSupport::TestCase
  fixtures :projects, :issues, :issue_statuses, :trackers, :users

  test 'rejects unknown status values' do
    filter = RedmineIssueLimitsWarning::ProjectIssuesFilter.new(Project.find(1))
    assert_empty filter.issue_ids_for('unknown')
  end

  test 'returns a relation with no rows when a status has no matching ids' do
    filter = RedmineIssueLimitsWarning::ProjectIssuesFilter.new(Project.find(1))
    filter.stubs(:issue_ids_for).with('ok').returns([])
    assert_equal 0, filter.issues_for('ok').count
  end

  test 'defines all supported summary statuses' do
    assert_equal %w[ok warning danger overdue without_estimate],
                 RedmineIssueLimitsWarning::ProjectIssuesFilter::STATUSES
  end
end
