module RedmineIssueLimitsWarning
  # Request-local batch evaluation: no shared/user-dependent cache or per-issue SUM.
  class Evaluation
    def self.call(issues)
      ids = issues.map(&:id)
      return {} if ids.empty?
      loaded = Issue.where(id: ids).includes(:status, project: :enabled_modules).to_a
      configs = IssueLimitsWarningProjectSetting.where(project_id: loaded.map(&:project_id).uniq).index_by(&:project_id)
      global = Settings.global
      settings_by_project = {}
      enabled_by_project = {}
      loaded.each do |issue|
        next if settings_by_project.key?(issue.project_id)
        settings = Settings.effective_for(issue.project, global_settings: global,
          project_config: configs[issue.project_id]&.settings_hash || {})
        settings_by_project[issue.project_id] = settings
        enabled_by_project[issue.project_id] = Settings.enabled_for?(issue.project, settings)
      end
      spent = TimeEntry.where(issue_id: ids).group(:issue_id).sum(:hours)
      loaded.to_h do |issue|
        settings = settings_by_project.fetch(issue.project_id)
        enabled = enabled_by_project.fetch(issue.project_id)
        hours = spent.fetch(issue.id, 0).to_f
        [issue.id, {spent_hours: hours,
                    time_budget: Checks::TimeBudget.call(issue, settings: settings,
                     spent_hours: hours, enabled: enabled),
                    due_date: Checks::DueDate.call(issue, settings: settings, enabled: enabled),
                    closed: issue.closed?}]
      end
    end
  end
end
