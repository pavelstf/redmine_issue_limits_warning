resources :projects, only: [] do
  resource :issue_limits_warning,
           controller: 'issue_limits_warning_project_settings',
           only: %i[edit update]

  get 'issue_limits_warning/:status',
      to: 'issue_limits_warning_issues#index',
      as: 'issue_limits_warning_issues',
      constraints: {status: /ok|warning|danger|unknown|overdue|without_estimate/}
end
get 'issue_limits_warning/time_entry_context', to: 'issue_limits_warning_time_context#show', as: 'rilw_time_entry_context'
