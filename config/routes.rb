resources :projects, only: [] do
  get 'issue_limits_warning/:status',
      to: 'issue_limits_warning_issues#index',
      as: 'issue_limits_warning_issues'

  resource :issue_limits_warning,
           controller: 'issue_limits_warning_project_settings',
           only: %i[edit update]
end
