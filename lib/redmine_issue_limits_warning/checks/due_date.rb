module RedmineIssueLimitsWarning
  module Checks
    class DueDate
      Result = Struct.new(:enabled, :overdue, :due_date, :days_overdue, :color, keyword_init: true) do
        def enabled?
          enabled
        end

        def overdue?
          overdue
        end

        def css_class
          overdue? ? 'rilw-due-date-overdue' : 'rilw-due-date-ok'
        end
      end

      class << self
        def call(issue, settings: nil, enabled: nil)
          settings ||= Settings.effective_for(issue.project)
          enabled = Settings.enabled_for?(issue.project, settings) if enabled.nil?

          return disabled_result unless enabled
          return disabled_result unless Settings.truthy?(settings['due_date_enabled'])
          return disabled_result unless issue.due_date
          return disabled_result if issue.closed?

          today = User.current.today
          overdue = issue.due_date < today

          Result.new(
            enabled: true,
            overdue: overdue,
            due_date: issue.due_date,
            days_overdue: overdue ? (today - issue.due_date).to_i : 0,
            color: Settings.color(settings, 'overdue_color')
          )
        end

        private

        def disabled_result
          Result.new(enabled: false, overdue: false)
        end
      end
    end
  end
end
