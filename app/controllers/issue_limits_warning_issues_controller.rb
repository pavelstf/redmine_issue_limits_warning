class IssueLimitsWarningIssuesController < ApplicationController
  SORT_COLUMNS = %w[cpi done_ratio].freeze

  before_action :find_project_by_project_id
  before_action :require_view_issues_permission
  before_action :require_enabled_module
  before_action :find_status

  helper :issues
  def index
    filter = RedmineIssueLimitsWarning::ProjectIssuesFilter.new(@project)
    column, direction = params[:sort].to_s.split(':', 2)
    if SORT_COLUMNS.include?(column) && %w[asc desc].include?(direction)
      @sort_column, @sort_direction = column, direction
      sorted_ids = filter.sorted_issue_ids_for(@status, column, descending: direction == 'desc')
    end
    scope = filter.issues_for(@status).includes(:tracker, :status, :assigned_to, :priority)

    @issue_count = sorted_ids ? sorted_ids.size : scope.count
    @issue_pages = Paginator.new @issue_count, per_page_option, params[:page]
    @issues = if sorted_ids
                page_ids = sorted_ids.slice(@issue_pages.offset, @issue_pages.per_page) || []
                scope.rewhere(id: page_ids).in_order_of(:id, page_ids).to_a
              else
                scope.order(id: :desc).limit(@issue_pages.per_page).offset(@issue_pages.offset).to_a
              end
    @rilw_evaluations = RedmineIssueLimitsWarning::Evaluation.call(@issues)
  end

  private

  def require_enabled_module
    render_404 unless RedmineIssueLimitsWarning::Settings.enabled_for?(@project)
  end

  def require_view_issues_permission
    render_403 unless User.current.allowed_to?(:view_issues, @project)
  end

  def find_status
    @status = params[:status].to_s
    render_404 unless RedmineIssueLimitsWarning::ProjectIssuesFilter::STATUSES.include?(@status)
  end
end
