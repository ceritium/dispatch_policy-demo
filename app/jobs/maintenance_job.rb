# frozen_string_literal: true

# Global cap — at most 3 concurrent maintenance jobs across the whole app.
# No partition: the cap is on total in-flight, not per tenant.
class MaintenanceJob < ApplicationJob
  include DispatchPolicy::Dispatchable

  dispatch_policy do
    gate :global_cap, max: 3
  end

  def perform(name:)
    sleep 1
    JobRun.create!(
      job_class: self.class.name,
      payload:   { name: name },
      ran_at:    Time.current
    )
  end
end
