module RedmineIssueLimitsWarning
  class ProjectIssuesFilter
    STATUSES = %w[ok warning danger overdue without_estimate].freeze

    attr_reader :project

    def initialize(project)
      @project = project
    end

    def counts
      STATUSES.each_with_object(Hash.new(0)) do |status, memo|
        memo[status.to_sym] = issue_ids_for(status).size
      end
    end

    def issues_for(status)
      issue_ids = issue_ids_for(status)
      return Issue.none if issue_ids.empty?

      base_scope.where(id: issue_ids)
    end

    def issue_ids_for(status)
      status = status.to_s
      return [] unless STATUSES.include?(status)

      matching_issue_ids[status]
    end

    private

    def matching_issue_ids
      @matching_issue_ids ||= begin
        ids = STATUSES.each_with_object({}) { |status, memo| memo[status] = [] }

        base_scope.find_each do |issue|
          time_budget = Checks::TimeBudget.call(issue)
          due_date = Checks::DueDate.call(issue)

          if issue.estimated_hours.to_f <= 0 && leaf_issue?(issue)
            ids['without_estimate'] << issue.id
          elsif time_budget.enabled?
            if time_budget.status == :danger || time_budget.status == :exceeded
              ids['danger'] << issue.id
            elsif ids.key?(time_budget.status.to_s)
              ids[time_budget.status.to_s] << issue.id
            end
          end

          ids['overdue'] << issue.id if due_date.overdue?
        end

        ids
      end
    end

    def base_scope
      Issue.visible.open.where(project_id: project.id)
    end

    def leaf_issue?(issue)
      issue.leaf?
    end
  end
end
