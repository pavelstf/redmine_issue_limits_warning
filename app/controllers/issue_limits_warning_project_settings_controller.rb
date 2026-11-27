class IssueLimitsWarningProjectSettingsController < ApplicationController
  menu_item :settings
  helper :projects

  before_action :find_project_by_project_id
  before_action :authorize_project_settings

  def edit
    redirect_to settings_project_path(@project, tab: 'issue_limits_warning')
  end

  def update
    attributes = project_settings_params
    RedmineIssueLimitsWarning::Settings.save_project_settings(@project, attributes)
    flash[:notice] = l(:notice_successful_update)
    redirect_to settings_project_path(@project, tab: 'issue_limits_warning')
  rescue ActiveRecord::RecordInvalid => error
    if attributes['new_record'] == '1' && error.record.errors.of_kind?(:project_id, :taken)
      return render_conflict
    end
    @record = error.record
    flash.now[:error] = @record.errors.full_messages.join(', ')
    render :edit, status: :unprocessable_entity
  rescue ActiveRecord::StaleObjectError, ActiveRecord::RecordNotUnique
    render_conflict
  end

  private

  def authorize_project_settings
    deny_access unless RedmineIssueLimitsWarning::Settings.editable_for?(@project, User.current)
  end

  def render_conflict
    @record = RedmineIssueLimitsWarning::Settings.project_settings_record(@project)
    flash.now[:error] = l(:error_rilw_stale_settings)
    render :edit, status: :conflict
  end

  def project_settings_params
    params.fetch(:issue_limits_warning, ActionController::Parameters.new).permit(
      :enabled,
      :override_thresholds,
      :cpi_warning, :cpi_danger, :absolute_limit_enabled, :absolute_limit_threshold, :lock_version, :new_record,
      :due_date_enabled
    )
  end
end
