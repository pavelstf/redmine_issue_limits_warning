require_relative 'lib/redmine_issue_limits_warning'

Redmine::Plugin.register :redmine_issue_limits_warning do
  name 'Redmine Issue Limits Warning'
  author 'PAvcho'
  description 'Adds visual warnings when issue spent time approaches estimates or due dates are overdue.'
  version '0.1.0'
  url 'https://github.com/pavelstf/redmine_issue_limits_warning'
  author_url 'https://github.com/pavelstf'

  requires_redmine version_or_higher: '5.0.0'

  settings(
    default: RedmineIssueLimitsWarning::Settings::DEFAULTS,
    partial: 'settings/redmine_issue_limits_warning'
  )

  project_module :issue_limits_warning do
    # Redmine discovers project modules through permissions. This marker grants no actions.
    permission :issue_limits_warning_module, {}, public: true
  end
end

# Redmine runs plugin initializers inside its own reload preparation callback.
require_dependency 'projects_helper'
require_relative 'lib/redmine_issue_limits_warning/projects_helper_patch'
ProjectsHelper.prepend(RedmineIssueLimitsWarning::ProjectsHelperPatch) unless ProjectsHelper < RedmineIssueLimitsWarning::ProjectsHelperPatch

require_dependency 'settings_controller'
require_relative 'lib/redmine_issue_limits_warning/settings_controller_patch'
SettingsController.prepend(RedmineIssueLimitsWarning::SettingsControllerPatch) unless SettingsController < RedmineIssueLimitsWarning::SettingsControllerPatch
