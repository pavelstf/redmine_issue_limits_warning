module RedmineIssueLimitsWarning
  module Checks
    class TimeBudget
      Result = Struct.new(
        :enabled,
        :status,
        :spent_hours,
        :estimated_hours,
        :ratio,
        :remaining_hours,
        :exceeded_hours,
        :color,
        keyword_init: true
      ) do
        def enabled?
          enabled
        end

        def ok?
          status == :ok
        end

        def warning?
          status == :warning
        end

        def danger?
          status == :danger || status == :exceeded
        end

        def exceeded?
          status == :exceeded
        end

        def css_class
          "rilw-time-budget-#{status}"
        end
      end

      class << self
        def call(issue)
          settings = Settings.effective_for(issue.project)

          return disabled_result unless Settings.enabled_for?(issue.project)
          return disabled_result unless Settings.truthy?(settings['time_budget_enabled'])
          return disabled_result if issue.closed?

          estimated_hours = issue.estimated_hours.to_f
          return disabled_result if estimated_hours <= 0

          spent_hours = issue.spent_hours.to_f
          ratio = estimated_hours.positive? ? (spent_hours / estimated_hours) * 100 : 0
          status = status_for(ratio, settings)

          Result.new(
            enabled: true,
            status: status,
            spent_hours: spent_hours,
            estimated_hours: estimated_hours,
            ratio: ratio,
            remaining_hours: [estimated_hours - spent_hours, 0].max,
            exceeded_hours: [spent_hours - estimated_hours, 0].max,
            color: color_for(status, settings)
          )
        end

        private

        def disabled_result
          Result.new(enabled: false, status: :none)
        end

        def status_for(ratio, settings)
          warning_threshold = Settings.threshold(settings, 'warning_threshold')
          danger_threshold = Settings.threshold(settings, 'danger_threshold')

          return :exceeded if ratio > 100
          return :danger if ratio >= danger_threshold
          return :warning if ratio >= warning_threshold

          :ok
        end

        def color_for(status, settings)
          case status
          when :ok
            Settings.color(settings, 'ok_color')
          when :warning
            Settings.color(settings, 'warning_color')
          else
            Settings.color(settings, 'danger_color')
          end
        end
      end
    end
  end
end
