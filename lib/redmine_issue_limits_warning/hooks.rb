module RedmineIssueLimitsWarning
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_issues_show_details_bottom,
              partial: 'redmine_issue_limits_warning/issue_show'

    render_on :view_issues_index_bottom,
              partial: 'redmine_issue_limits_warning/issues_index'

    render_on :view_projects_show_right,
              partial: 'redmine_issue_limits_warning/project_overview'

    render_on :view_timelog_edit_form_bottom,
              partial: 'redmine_issue_limits_warning/time_entry_warning'

    def view_layouts_base_html_head(context = {})
      stylesheet_link_tag('redmine_issue_limits_warning', plugin: 'redmine_issue_limits_warning') +
        javascript_include_tag('redmine_issue_limits_warning', plugin: 'redmine_issue_limits_warning')
    end
  end
end
