module RedmineIssueLimitsWarning
  # Intercept only our native global-settings POST to validate before saving.
  module SettingsControllerPatch
    def plugin
      return super unless request.post? && params[:id].to_s == 'redmine_issue_limits_warning'
      @plugin = Redmine::Plugin.find(:redmine_issue_limits_warning)
      @settings, errors = Settings.save_global(params.fetch(:settings, ActionController::Parameters.new).to_unsafe_h)
      if errors.any?
        @partial = @plugin.settings[:partial]
        flash.now[:error] = errors.map { |key| l(key) }.join(' ')
        render :plugin, status: :unprocessable_entity
      else
        flash[:notice] = l(:notice_successful_update)
        redirect_to plugin_settings_path(@plugin)
      end
    end
  end
end
