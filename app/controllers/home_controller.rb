# frozen_string_literal: true

class HomeController < ApplicationController
  ACCOUNTS = %w[A B C].freeze

  JOB_CLASSES = [
    EmailJob,
    ReportJob,
    TenantWorkJob,
    MaintenanceJob
  ].freeze

  def index
    @accounts = ACCOUNTS
  end

  def stats
    @recent = JobRun.recent.limit(50)
    @counts = JOB_CLASSES.map do |klass|
      policy_name = klass.resolved_dispatch_policy.name
      scope = DispatchPolicy::StagedJob.where(policy_name: policy_name)
      {
        name:      klass.name,
        pending:   scope.pending.count,
        admitted:  scope.admitted.count,
        completed: scope.completed.where(completed_at: 24.hours.ago..).count
      }
    end
  end
end
