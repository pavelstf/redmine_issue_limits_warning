class IssueLimitsWarningIssuesController < ApplicationController
  before_action :find_project_by_project_id
  before_action :require_view_issues_permission
  before_action :find_status

  helper :issues
  helper :sort

  def index
    filter = RedmineIssueLimitsWarning::ProjectIssuesFilter.new(@project)
    scope = filter.issues_for(@status).includes(:tracker, :status, :assigned_to, :priority)

    @issue_count = scope.count
    @issue_pages = Paginator.new @issue_count, per_page_option, params[:page]
    @issues = scope.order("#{Issue.table_name}.id DESC").limit(@issue_pages.per_page).offset(@issue_pages.offset).to_a
  end

  private

  def require_view_issues_permission
    render_403 unless User.current.allowed_to?(:view_issues, @project)
  end

  def find_status
    @status = params[:status].to_s
    render_404 unless RedmineIssueLimitsWarning::ProjectIssuesFilter::STATUSES.include?(@status)
  end
end
