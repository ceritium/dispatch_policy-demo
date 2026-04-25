# frozen_string_literal: true

# Demo for :fair_time_share. Each account_id has a *fixed* per-job sleep
# below, so the only variable is who's publishing. The throttle is the
# absolute ceiling per account; fair_time_share reorders admissions so
# the policy's effective compute time is split evenly across whichever
# accounts are currently active.
#
# Try it: hit the StormFairShare form. With a single account active,
# you'll see throughput cap at the throttle (60/min). Add a second
# account: both share the policy's throughput in proportion to their
# duration. The slow one gets fewer admissions, the fast one gets more,
# and total compute time per minute stays balanced.
class WebhookDeliveryJob < ApplicationJob
  queue_as :default

  # Deterministic per-account latency. Pick from this set in the form.
  ACCOUNT_LATENCIES_MS = {
    "fast"   => 50,
    "medium" => 200,
    "slow"   => 1_000
  }.freeze

  include DispatchPolicy::Dispatchable

  dispatch_policy do
    context ->(args) {
      opts = args.first || {}
      { account_id: opts[:account_id] }
    }

    # 60 deliveries/min/account is the absolute ceiling.
    gate :throttle,
         rate:         60,
         per:          1.minute,
         partition_by: ->(ctx) { ctx[:account_id] }

    # Bias admission ordering toward whichever account has consumed the
    # least compute time in the last 60s. Solo accounts are unaffected.
    gate :fair_time_share, window: 60
  end

  def perform(account_id:, **)
    sleep_ms = ACCOUNT_LATENCIES_MS.fetch(account_id, 100)
    sleep(sleep_ms / 1000.0)

    JobRun.create!(
      job_class:  self.class.name,
      account_id: account_id,
      payload:    { sleep_ms: sleep_ms },
      ran_at:     Time.current
    )
  end
end
