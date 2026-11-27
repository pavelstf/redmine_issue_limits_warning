module RedmineIssueLimitsWarning
  class ProjectIssuesFilter
    STATUSES = %w[ok warning danger unknown overdue without_estimate].freeze
    attr_reader :project
    def initialize(project)
      @project = project
    end

    def counts
      STATUSES.to_h { |status| [status.to_sym, issue_ids_for(status).size] }
    end

    def issues_for(status)
      base_scope.where(id: issue_ids_for(status))
    end

    def issue_ids_for(status)
      return [] unless STATUSES.include?(status.to_s)
      matching_issue_ids.fetch(status.to_s)
    end

    private

    def matching_issue_ids
      @matching_issue_ids ||= begin
        ids = STATUSES.to_h { |status| [status, []] }
        if Settings.enabled_for?(project)
          base_scope.find_in_batches(batch_size: 500) do |batch|
            evaluations = Evaluation.call(batch)
            batch.each do |issue|
              result = evaluations.fetch(issue.id)
              budget = result[:time_budget]
              if issue.leaf? && issue.estimated_hours.to_f <= 0
                ids['without_estimate'] << issue.id
              elsif budget.enabled?
                ids[budget.status.to_s] << issue.id
              end
              ids['overdue'] << issue.id if result[:due_date].overdue?
            end
          end
        end
        ids
      end
    end

    def base_scope
      Issue.visible.open.where(project_id: project.id)
    end
  end
end
