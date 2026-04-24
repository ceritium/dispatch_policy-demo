# frozen_string_literal: true

# No gates — max throughput. round_robin_by guarantees that even a tenant
# dumping thousands of jobs can't starve others: the LATERAL batch gives
# each active account up to round_robin_quantum rows per tick.
class TenantWorkJob < ApplicationJob
  include DispatchPolicy::Dispatchable

  dispatch_policy do
    context ->(args) {
      opts = args.first || {}
      { account_id: opts[:account_id] }
    }

    round_robin_by ->(args) { (args.first || {})[:account_id] }
  end

  def perform(account_id:, task:)
    sleep 0.2
    JobRun.create!(
      job_class:  self.class.name,
      account_id: account_id,
      payload:    { task: task },
      ran_at:     Time.current
    )
  end
end
