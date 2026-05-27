module RedmineIssueLimitsWarning
  class ProjectSummary
    attr_reader :project

    def initialize(project)
      @project = project
    end

    def counts
      @counts ||= ProjectIssuesFilter.new(project).counts
    end
  end
end
