module RedmineIssueLimitsWarning
  module Checks
    class TimeBudget
      Result = Struct.new(:enabled, :status, :cpi_status, :spent_hours, :estimated_hours,
        :ratio, :remaining_hours, :exceeded_hours, :color, :cpi, :done_ratio,
        :forecast_hours, :absolute_limit_reached, :absolute_limit_threshold, :reason, keyword_init: true) do
        def enabled?; enabled; end
        def ok?; status == :ok; end
        def warning?; status == :warning; end
        def danger?; status == :danger; end
        def exceeded?; exceeded_hours.to_f > 0; end
        def css_class; "rilw-time-budget-#{status}"; end
      end

      def self.call(issue, settings: nil, spent_hours: nil, enabled: nil)
        settings ||= Settings.effective_for(issue.project)
        enabled = Settings.enabled_for?(issue.project, settings) if enabled.nil?
        cpi_enabled = Settings.truthy?(settings['time_budget_enabled'])
        absolute_enabled = Settings.truthy?(settings['absolute_limit_enabled'])
        unless enabled && !issue.closed? && issue.leaf? && (cpi_enabled || absolute_enabled)
          return Result.new(enabled: false, status: :none)
        end
        estimate = issue.estimated_hours.to_f
        spent = spent_hours.nil? ? issue.spent_hours.to_f : spent_hours.to_f
        estimate = 0 unless estimate.finite? && estimate > 0
        spent = 0 unless spent.finite? && spent >= 0
        progress = issue.done_ratio
        valid_progress = progress && progress.to_f.finite? && progress.to_f.between?(0, 100)
        if estimate > 0 && spent > 0 && valid_progress
          value = estimate * (progress.to_f / 100) / spent
          cpi = value.round(12) if value.finite?
        end
        cpi_status = if !cpi_enabled || cpi.nil?
                       :unknown
                     elsif cpi < Settings.threshold(settings, 'cpi_danger')
                       :danger
                     elsif cpi < Settings.threshold(settings, 'cpi_warning')
                       :warning
                     else
                       :ok
                     end
        ratio = spent / estimate * 100 if estimate > 0
        absolute_limit_threshold = Settings.threshold(settings, 'absolute_limit_threshold') if absolute_enabled
        reached = absolute_limit_threshold && ratio && ratio >= absolute_limit_threshold
        status = reached ? :danger : cpi_status
        reason = if estimate <= 0
                   :missing_estimate
                 elsif spent <= 0
                   :no_spent_hours
                 elsif !valid_progress
                   :missing_progress
                 elsif progress.to_f.zero?
                   :no_progress
                 end
        color_key = {ok: 'ok_color', warning: 'warning_color', danger: 'danger_color'}[status]
        Result.new(enabled: true, status: status, cpi_status: cpi_status, cpi: cpi,
          estimated_hours: estimate, spent_hours: spent, done_ratio: progress, ratio: ratio,
          forecast_hours: (spent / (progress.to_f / 100) if estimate > 0 && spent > 0 && valid_progress && progress.to_f > 0),
          remaining_hours: [estimate - spent, 0].max,
          exceeded_hours: estimate > 0 ? [spent - estimate, 0].max : 0,
          absolute_limit_reached: !!reached, absolute_limit_threshold: absolute_limit_threshold, reason: reason,
          color: color_key ? Settings.color(settings, color_key) : '#777777')
      end
    end
  end
end
