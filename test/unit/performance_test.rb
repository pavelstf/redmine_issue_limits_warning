require_relative '../test_helper'

class RilwPerformanceTest < ActiveSupport::TestCase
  def test_sql_queries_grow_by_batches_not_by_issue
    User.current = User.find(1)
    project = Project.find(1)
    project.enable_module!(:issue_limits_warning)
    Setting.plugin_redmine_issue_limits_warning = RedmineIssueLimitsWarning::Settings::DEFAULTS.dup
    template = Issue.find(1).attributes.except('id').merge('project_id' => 1, 'parent_id' => nil,
      'root_id' => nil, 'lft' => 1, 'rgt' => 2, 'status_id' => 1, 'estimated_hours' => 100, 'done_ratio' => 50)
    counts = []
    previous_size = 0
    [50, 500, 5000].each do |size|
      Issue.insert_all!((size - previous_size).times.map { template.merge('subject' => 'CPI SQL volume') })
      previous_size = size
      Issue.where(subject: 'CPI SQL volume', root_id: nil).update_all('root_id = id')
      batches = (Issue.visible.open.where(project_id: project.id).count / 500.0).ceil
      sql = []
      subscriber = ->(_name, _start, _finish, _id, payload) { sql << payload[:sql] unless payload[:name] == 'SCHEMA' || payload[:cached] }
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      ActiveSupport::Notifications.subscribed(subscriber, 'sql.active_record') do
        RedmineIssueLimitsWarning::ProjectIssuesFilter.new(project).counts
      end
      counts << sql.count { |statement| statement.match?(/\ASELECT/i) }
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
      puts "RILW SQL: #{size} added issues, #{counts.last} SELECT queries, #{elapsed.round(3)}s"
      sums = sql.grep(/SUM\(.*hours/i)
      assert_operator sums.size, :<=, batches, "#{size} issues: #{sums.size} SUM queries"
      assert_operator counts.last, :<=, 8 + 8 * batches, "#{size} issues: #{counts.last} SELECT queries"
    end
    assert_operator counts[1] - counts[0], :<=, 12
  ensure
    User.current = nil
  end
end
