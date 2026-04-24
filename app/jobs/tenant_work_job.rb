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

    # perform sleeps on a Perlin curve (100–500ms, drifting every ~30s).
    # target_lag_ms around the upper end of the curve lets current_max
    # grow during quiet stretches and shrink when the curve peaks.
    gate :adaptive_concurrency,
         partition_by:  ->(ctx) { ctx[:account_id] },
         initial_max:   3,
         target_lag_ms: 5000
  end

  def perform(account_id:, task:)
    LoadSimulator.sleep_for(account_id, base_ms: 100, amplitude_ms: 400)
    JobRun.create!(
      job_class:  self.class.name,
      account_id: account_id,
      payload:    { task: task },
      ran_at:     Time.current
    )
  end
end
