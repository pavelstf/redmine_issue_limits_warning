class IssueLimitsWarningTimeContextController < ApplicationController
  before_action :require_login

  def show
    issue = Issue.visible.find_by(id: params[:issue_id])
    return render_404 unless issue
    return render_403 unless User.current.allowed_to?(:log_time, issue.project)
    settings = RedmineIssueLimitsWarning::Settings.effective_for(issue.project)
    return render_404 unless RedmineIssueLimitsWarning::Settings.enabled_for?(issue.project, settings)
    return render_404 unless RedmineIssueLimitsWarning::Settings.truthy?(settings['warn_on_time_entry'])
    entry = nil
    if params[:time_entry_id].present?
      entry = TimeEntry.find_by(id: params[:time_entry_id])
      return render_403 unless entry && entry.editable_by?(User.current)
    end
    budget = RedmineIssueLimitsWarning::Checks::TimeBudget.call(issue, settings: settings)
    return render json: {enabled: false} unless budget.enabled?
    previous = entry && entry.issue_id == issue.id ? entry.hours.to_f : 0
    response.headers['Cache-Control'] = 'no-store'
    render json: {enabled: true, spent_hours: budget.spent_hours - previous,
      estimated_hours: budget.estimated_hours, done_ratio: budget.done_ratio,
      cpi_enabled: RedmineIssueLimitsWarning::Settings.truthy?(settings['time_budget_enabled']),
      cpi_warning: RedmineIssueLimitsWarning::Settings.threshold(settings, 'cpi_warning'),
      cpi_danger: RedmineIssueLimitsWarning::Settings.threshold(settings, 'cpi_danger'),
      absolute_limit_enabled: RedmineIssueLimitsWarning::Settings.truthy?(settings['absolute_limit_enabled']),
      absolute_limit_threshold: RedmineIssueLimitsWarning::Settings.threshold(settings, 'absolute_limit_threshold'),
      danger_color: RedmineIssueLimitsWarning::Settings.color(settings, 'danger_color'),
      warning_color: RedmineIssueLimitsWarning::Settings.color(settings, 'warning_color')}
  end
end
