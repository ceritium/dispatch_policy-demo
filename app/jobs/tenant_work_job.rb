# frozen_string_literal: true

# Combines round_robin_by (fairness across tenants at fetch time) with
# adaptive_concurrency (backpressure per tenant at admission time). The cap
# per account shrinks when that account's performs run slow or fail and
# grows back when they recover.
class TenantWorkJob < ApplicationJob
  include DispatchPolicy::Dispatchable

  # Fake per-account latency so the feedback loop has something to react to.
  SIMULATED_LATENCY_MS = { "A" => 100, "B" => 400, "C" => 900 }.freeze

  dispatch_policy do
    context ->(args) {
      opts = args.first || {}
      { account_id: opts[:account_id] }
    }

    round_robin_by ->(args) { (args.first || {})[:account_id] }

    gate :adaptive_concurrency,
         partition_by:   ->(ctx) { ctx[:account_id] },
         initial_max:    3,
         target_latency: 300  # ms
  end

  def perform(account_id:, task:)
    latency_ms = 300
    # sleep(latency_ms / 1000.0)
    sleep(0.2)
    JobRun.create!(
      job_class:  self.class.name,
      account_id: account_id,
      payload:    { task: task, latency_ms: latency_ms },
      ran_at:     Time.current
    )
  end
end
