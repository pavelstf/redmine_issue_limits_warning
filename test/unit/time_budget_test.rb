require File.expand_path('../test_helper', __dir__)

class RedmineIssueLimitsWarningTimeBudgetTest < ActiveSupport::TestCase
  IssueDouble = Struct.new(:project, :estimated_hours, :spent_hours, :closed_flag) do
    def closed?
      closed_flag
    end
  end

  def setup
    @project = Object.new
    @settings = RedmineIssueLimitsWarning::Settings::DEFAULTS.merge(
      'warning_threshold' => '80',
      'danger_threshold' => '100'
    )
  end

  test 'classifies time budget boundaries and exceeded estimates' do
    with_settings do
      assert_equal :ok, call_with(79).status
      assert_equal :warning, call_with(80).status
      assert_equal :danger, call_with(100).status

      exceeded = call_with(125)
      assert_equal :exceeded, exceeded.status
      assert_equal 2.5, exceeded.exceeded_hours
      assert exceeded.danger?
    end
  end

  test 'is disabled for closed issues and issues without an estimate' do
    with_settings do
      refute call_with(50, estimated: 0).enabled?
      refute call_with(50, closed: true).enabled?
    end
  end

  test 'uses configured colors' do
    with_settings do
      assert_equal '#f59e0b', call_with(80).color
      assert_equal '#dc2626', call_with(100).color
    end
  end

  private

  def call_with(ratio, estimated: 10.0, closed: false)
    issue = IssueDouble.new(@project, estimated, estimated * ratio / 100.0, closed)
    RedmineIssueLimitsWarning::Checks::TimeBudget.call(issue)
  end

  def with_settings(&block)
    RedmineIssueLimitsWarning::Settings.stub(:effective_for, @settings) do
      RedmineIssueLimitsWarning::Settings.stub(:enabled_for?, true, &block)
    end
  end
end
