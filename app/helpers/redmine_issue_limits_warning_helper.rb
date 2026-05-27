module RedmineIssueLimitsWarningHelper
  def rilw_time_budget_badge(issue)
    result = RedmineIssueLimitsWarning::Checks::TimeBudget.call(issue)
    return ''.html_safe unless result.enabled?

    render(
      partial: 'redmine_issue_limits_warning/time_budget_badge',
      locals: { issue: issue, result: result }
    )
  end

  def rilw_due_date_badge(issue)
    result = RedmineIssueLimitsWarning::Checks::DueDate.call(issue)
    return ''.html_safe unless result.enabled? && result.overdue?

    render(
      partial: 'redmine_issue_limits_warning/due_date_badge',
      locals: { issue: issue, result: result }
    )
  end

  def rilw_format_hours(value)
    number_with_precision(value.to_f, precision: 2, strip_insignificant_zeros: true)
  end

  def rilw_format_ratio(value)
    number_to_percentage(value.to_f, precision: 0)
  end
end
