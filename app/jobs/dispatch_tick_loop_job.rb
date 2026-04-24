# frozen_string_literal: true

# Drives DispatchPolicy::TickLoop. The gem is adapter-agnostic; dedup for
# "only one tick in flight" lives here, using GoodJob's concurrency
# extension. total_limit counts performing jobs too, so the cron safety
# net can't stack duplicate enqueues on top of the running self-chain.
class DispatchTickLoopJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(
    total_limit: 1,
    key: -> { "dispatch_tick_loop:#{arguments.first || 'all'}" }
  )

  def perform(policy_name = nil)
    deadline = Time.current + DispatchPolicy.config.tick_max_duration

    DispatchPolicy::TickLoop.run(
      policy_name: policy_name,
      stop_when:   -> {
        GoodJob.current_thread_shutting_down? || Time.current >= deadline
      }
    )

    # Self-chain — cron is only the safety net.
    DispatchTickLoopJob.set(wait: 1.second).perform_later(policy_name)
  end
end
