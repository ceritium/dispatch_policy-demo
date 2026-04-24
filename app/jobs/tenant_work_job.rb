# frozen_string_literal: true

# Combines round_robin_by (fairness across tenants at fetch time) with
# adaptive_concurrency (backpressure per tenant at admission time). The
# gate grows current_max while the adapter queue stays under target_lag_ms
# (workers hungry, admit more) and shrinks it when the queue backs up.
class TenantWorkJob < ApplicationJob
  include DispatchPolicy::Dispatchable

  dispatch_policy do
    context ->(args) {
      opts = args.first || {}
      { account_id: opts[:account_id] }
    }

    round_robin_by ->(args) { (args.first || {})[:account_id] }

    # perform sleeps ~200ms. target_lag_ms ≈ perform × 0.5 keeps workers
    # constantly fed (~100ms of queue buffer) without over-admitting.
    gate :adaptive_concurrency,
         partition_by:  ->(ctx) { ctx[:account_id] },
         initial_max:   3,
         target_lag_ms: 5000
  end

  def perform(account_id:, task:)
    # sleep(0.2)
    JobRun.create!(
      job_class:  self.class.name,
      account_id: account_id,
      payload:    { task: task },
      ran_at:     Time.current
    )
  end
end
