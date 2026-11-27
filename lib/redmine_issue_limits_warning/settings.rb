module RedmineIssueLimitsWarning
  class Settings
    DEFAULTS = {
      'time_budget_enabled' => '1', 'cpi_warning' => '0.90', 'cpi_danger' => '0.80',
      'absolute_limit_enabled' => '0', 'absolute_limit_threshold' => '100',
      'ok_color' => '#16a34a', 'warning_color' => '#f59e0b', 'danger_color' => '#dc2626',
      'due_date_enabled' => '1', 'overdue_color' => '#dc2626',
      'show_on_issue_show' => '1', 'show_on_issue_list' => '1',
      'show_ok_issue_list_marker' => '0',
      'show_on_project_overview' => '1', 'warn_on_time_entry' => '1'
    }.freeze
    PROJECT_KEYS = %w[enabled override_thresholds cpi_warning cpi_danger
                      absolute_limit_enabled absolute_limit_threshold due_date_enabled].freeze
    BOOLEAN_KEYS = %w[time_budget_enabled absolute_limit_enabled due_date_enabled
                      show_on_issue_show show_on_issue_list show_ok_issue_list_marker
                      show_on_project_overview warn_on_time_entry].freeze

    class << self
      def global
        DEFAULTS.merge((Setting.plugin_redmine_issue_limits_warning || {}).slice(*DEFAULTS.keys))
      end

      def effective_for(project, global_settings: global, project_config: nil)
        config = project_config || project_settings_for(project)
        settings = global_settings.dup
        settings['project_enabled'] = config.fetch('enabled', '1')
        settings['due_date_enabled'] = config['due_date_enabled'] if config.key?('due_date_enabled')
        if truthy?(config['override_thresholds'])
          %w[cpi_warning cpi_danger absolute_limit_enabled absolute_limit_threshold].each do |key|
            settings[key] = config[key] if config.key?(key)
          end
        end
        settings
      end

      def enabled_for?(project, settings = nil)
        project.present? && project.enabled_modules.any? { |mod| mod.name == 'issue_limits_warning' && !mod.destroyed? } &&
          truthy?((settings || effective_for(project))['project_enabled'])
      end

      def project_settings_for(project)
        return {} unless project
        record = IssueLimitsWarningProjectSetting.find_by(project_id: project.id)
        record ? record.settings_hash : {}
      end

      def editable_for?(project, user)
        project.module_enabled?(:issue_limits_warning) && user.allowed_to?(:edit_project, project)
      end

      def project_settings_record(project)
        record = IssueLimitsWarningProjectSetting.find_or_initialize_by(project_id: project.id)
        if record.new_record?
          record.assign_attributes(global.slice(
            'cpi_warning', 'cpi_danger', 'absolute_limit_enabled', 'absolute_limit_threshold', 'due_date_enabled'))
        end
        record
      end

      def save_project_settings(project, attributes)
        record = IssueLimitsWarningProjectSetting.find_or_initialize_by(project_id: project.id)
        if record.persisted? && attributes['new_record'].to_s == '1'
          raise ActiveRecord::StaleObjectError.new(record, 'update')
        end
        record.assign_attributes(attributes.slice(*PROJECT_KEYS, 'lock_version'))
        record.save!
        record
      end

      def errors_for(settings)
        errors = []
        warning = number(settings['cpi_warning'])
        danger = number(settings['cpi_danger'])
        limit = number(settings['absolute_limit_threshold'])
        errors << :error_rilw_cpi_thresholds unless warning && danger && danger > 0 && danger <= warning && warning <= 1
        errors << :error_rilw_absolute_threshold unless limit && limit > 0 && limit <= 999
        %w[ok_color warning_color danger_color overdue_color].each do |key|
          errors << :error_rilw_color unless settings[key].to_s.match?(/\A#[0-9a-fA-F]{6}\z/)
        end
        errors.uniq
      end

      def save_global(attributes)
        candidate = global.merge(attributes.slice(*DEFAULTS.keys))
        errors = errors_for(candidate)
        return [candidate, errors] if errors.any?
        %w[cpi_warning cpi_danger absolute_limit_threshold].each do |key|
          candidate[key] = number(candidate[key]).to_s
        end
        BOOLEAN_KEYS.each { |key| candidate[key] = truthy?(candidate[key]) ? '1' : '0' }
        Setting.plugin_redmine_issue_limits_warning =
          (Setting.plugin_redmine_issue_limits_warning || {}).merge(candidate)
        [candidate, []]
      end

      def number(value)
        parsed = Float(value.to_s.tr(',', '.'), exception: false)
        parsed if parsed&.finite?
      end

      def threshold(settings, key)
        number(settings[key]) || DEFAULTS.fetch(key).to_f
      end

      def color(settings, key)
        value = settings[key].to_s
        value.match?(/\A#[0-9a-fA-F]{6}\z/) ? value : DEFAULTS[key]
      end

      def truthy?(value)
        value == true || value.to_s == '1'
      end
    end
  end
end
