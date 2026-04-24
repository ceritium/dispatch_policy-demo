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

    respond_to do |format|
      format.html
      format.json do
        render json: {
          counts: @counts,
          recent: @recent.map { |r|
            {
              job_class:  r.job_class,
              account_id: r.account_id,
              payload:    r.payload,
              ran_at:     r.ran_at&.iso8601
            }
          }
        }
      end
    end
  end
end
