# frozen_string_literal: true

# At most 2 reports can run at the same time per account. fair_interleave
# mixes accounts in the admission order so workers alternate tenants.
class ReportJob < ApplicationJob
  include DispatchPolicy::Dispatchable

  dispatch_policy do
    context ->(args) {
      opts = args.first || {}
      { account_id: opts[:account_id] }
    }

    gate :concurrency,
         max:          2,
         partition_by: ->(ctx) { ctx[:account_id] }

    gate :fair_interleave
  end

  def perform(account_id:, report_id:)
    sleep 0.5
    JobRun.create!(
      job_class:  self.class.name,
      account_id: account_id,
      payload:    { report_id: report_id },
      ran_at:     Time.current
    )
  end
end
