require File.expand_path('../test_helper', __dir__)

class RedmineIssueLimitsWarningDueDateTest < ActiveSupport::TestCase
  IssueDouble = Struct.new(:project, :due_date, :closed_flag) do
    def closed?
      closed_flag
    end
  end

  UserDouble = Struct.new(:today)

  def setup
    @project = Object.new
    @today = Date.new(2026, 7, 13)
    @settings = RedmineIssueLimitsWarning::Settings::DEFAULTS
  end

  test 'reports overdue days for an open issue' do
    with_settings do
      User.stubs(:current).returns(UserDouble.new(@today))
      result = call_with(@today - 3)
      assert result.enabled?
      assert result.overdue?
      assert_equal 3, result.days_overdue
      assert_equal '#dc2626', result.color
    end
  end

  test 'does not report an issue due today as overdue' do
    with_settings do
      User.stubs(:current).returns(UserDouble.new(@today))
      result = call_with(@today)
      assert result.enabled?
      refute result.overdue?
    end
  end

  test 'is disabled for closed issues and issues without a due date' do
    with_settings do
      refute call_with(nil).enabled?
      refute call_with(@today - 1, closed: true).enabled?
    end
  end

  private

  def call_with(due_date, closed: false)
    RedmineIssueLimitsWarning::Checks::DueDate.call(IssueDouble.new(@project, due_date, closed))
  end

  def with_settings(&block)
    RedmineIssueLimitsWarning::Settings.stubs(:effective_for).with(@project).returns(@settings)
    RedmineIssueLimitsWarning::Settings.stubs(:enabled_for?).with(@project).returns(true)
    block.call
  end
end
