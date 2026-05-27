require_relative 'lib/redmine_issue_limits_warning'

Redmine::Plugin.register :redmine_issue_limits_warning do
  name 'Redmine Issue Limits Warning'
  author 'PAvcho'
  description 'Adds visual warnings when issue spent time approaches estimates or due dates are overdue.'
  version '0.1.0'
  url 'https://github.com/PAvcho/redmine_issue_limits_warning'
  author_url 'https://github.com/PAvcho'

  requires_redmine version_or_higher: '5.0.0'

  settings(
    default: RedmineIssueLimitsWarning::Settings::DEFAULTS,
    partial: 'settings/redmine_issue_limits_warning'
  )

  project_module :issue_limits_warning do
    permission(
      :manage_issue_limits_warning,
      { issue_limits_warning_project_settings: %i[edit update] },
      require: :member
    )
  end

  menu(
    :project_menu,
    :issue_limits_warning,
    { controller: 'issue_limits_warning_project_settings', action: 'edit' },
    caption: :label_issue_limits_warning,
    after: :settings,
    param: :project_id
  )
end
