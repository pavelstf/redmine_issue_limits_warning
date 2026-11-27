module RedmineIssueLimitsWarning
  module ProjectsHelperPatch
    def project_settings_tabs
      tabs = super
      if Settings.editable_for?(@project, User.current)
        tabs << {name: 'issue_limits_warning', partial: 'issue_limits_warning_project_settings/form',
                 label: :label_issue_limits_warning}
      end
      tabs
    end
  end
end
