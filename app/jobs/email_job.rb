# frozen_string_literal: true

# Throttled email job — at most 5 enqueues admitted per minute per account,
# dedupes identical (account, subject) while pending.
class EmailJob < ApplicationJob
  include DispatchPolicy::Dispatchable

  dispatch_policy do
    context ->(args) {
      opts = args.first || {}
      { account_id: opts[:account_id] }
    }

    dedupe_key ->(args) {
      opts = args.first || {}
      "email:#{opts[:account_id]}:#{opts[:subject]}"
    }

    gate :throttle,
         rate:         5,
         per:          1.minute,
         partition_by: ->(ctx) { ctx[:account_id] }
  end

  def perform(account_id:, subject:)
    sleep 0.2
    JobRun.create!(
      job_class:  self.class.name,
      account_id: account_id,
      payload:    { subject: subject },
      ran_at:     Time.current
    )
  end
end
