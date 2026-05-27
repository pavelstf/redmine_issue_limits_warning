class IssueLimitsWarningProjectSettingsController < ApplicationController
  before_action :find_project_by_project_id
  before_action :authorize

  def edit
    @settings = RedmineIssueLimitsWarning::Settings.project_settings_for(@project)
  end

  def update
    RedmineIssueLimitsWarning::Settings.save_project_settings(@project, project_settings_params)
    flash[:notice] = l(:notice_successful_update)
    redirect_to edit_project_issue_limits_warning_path(@project)
  end

  private

  def project_settings_params
    params.fetch(:issue_limits_warning, {}).permit(
      :enabled,
      :override_thresholds,
      :warning_threshold,
      :danger_threshold,
      :due_date_enabled
    )
  end
end
