# frozen_string_literal: true

Rails.application.config.active_job.queue_adapter = :good_job
Rails.application.config.good_job.execution_mode = :external
Rails.application.config.good_job.enable_cron = true
Rails.application.config.good_job.cron = {
  dispatch_policy_tick: {
    cron: "*/10 * * * * *",
    class: "DispatchTickLoopJob",
    description: "Safety-net enqueue for the DispatchPolicy tick loop (self-chains in normal operation)."
  }
}
