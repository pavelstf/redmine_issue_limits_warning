module RedmineIssueLimitsWarning
  class Settings
    DEFAULTS = {
      'time_budget_enabled' => '1',
      'warning_threshold' => '80',
      'danger_threshold' => '100',
      'ok_color' => '#16a34a',
      'warning_color' => '#f59e0b',
      'danger_color' => '#dc2626',
      'due_date_enabled' => '1',
      'overdue_color' => '#dc2626',
      'show_on_issue_show' => '1',
      'show_on_issue_list' => '1',
      'show_on_project_overview' => '1',
      'warn_on_time_entry' => '1',
      'project_settings' => {}
    }.freeze

    class << self
      def global
        DEFAULTS.merge(Setting.plugin_redmine_issue_limits_warning || {})
      end

      def effective_for(project)
        settings = global.deep_dup
        project_config = project_settings_for(project)

        settings['project_enabled'] = project_config.fetch('enabled', '1')
        settings['due_date_enabled'] = project_config['due_date_enabled'] if project_config.key?('due_date_enabled')

        if truthy?(project_config['override_thresholds'])
          settings['warning_threshold'] = project_config['warning_threshold'].presence || settings['warning_threshold']
          settings['danger_threshold'] = project_config['danger_threshold'].presence || settings['danger_threshold']
        end

        settings
      end

      def enabled_for?(project)
        return true unless project

        truthy?(effective_for(project)['project_enabled'])
      end

      def project_settings_for(project)
        return {} unless project

        all_project_settings[project.id.to_s] || {}
      end

      def all_project_settings
        raw = global['project_settings']
        raw.is_a?(Hash) ? raw : {}
      end

      def save_project_settings(project, attributes)
        settings = global.deep_dup
        project_settings = all_project_settings.deep_dup
        project_settings[project.id.to_s] = sanitize_project_settings(attributes)
        settings['project_settings'] = project_settings
        Setting.plugin_redmine_issue_limits_warning = settings
      end

      def threshold(settings, key)
        value = settings[key].to_f
        value.positive? ? value : DEFAULTS[key].to_f
      end

      def color(settings, key)
        value = settings[key].to_s
        value.match?(/\A#[0-9a-fA-F]{6}\z/) ? value : DEFAULTS[key]
      end

      def truthy?(value)
        value == true || value.to_s == '1'
      end

      private

      def sanitize_project_settings(attributes)
        attributes ||= {}

        {
          'enabled' => truthy?(attributes['enabled']) ? '1' : '0',
          'override_thresholds' => truthy?(attributes['override_thresholds']) ? '1' : '0',
          'warning_threshold' => numeric_string(attributes['warning_threshold']),
          'danger_threshold' => numeric_string(attributes['danger_threshold']),
          'due_date_enabled' => truthy?(attributes['due_date_enabled']) ? '1' : '0'
        }
      end

      def numeric_string(value)
        number = value.to_s.tr(',', '.').to_f
        number.positive? ? number.to_s : ''
      end
    end
  end
end
