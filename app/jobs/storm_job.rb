# frozen_string_literal: true

# Stress-tester: for `duration_seconds` seconds, enqueue TenantWorkJob
# for many different account_ids, sampling with weight = account number
# (so acc_100 is 100× more likely than acc_1). Lets you exercise the
# admin UI and the adaptive gate with hundreds of partitions and a
# skewed distribution.
class StormJob < ApplicationJob
  queue_as :default

  def perform(num_accounts: 100, duration_seconds: 60, batch_size: 20, tick_ms: 200)
    deadline     = Time.current + duration_seconds
    total_weight = num_accounts * (num_accounts + 1) / 2

    while Time.current < deadline
      jobs = Array.new(batch_size) {
        acc = weighted_sample(num_accounts, total_weight)
        TenantWorkJob.new(account_id: "acc_#{acc}", task: "storm-#{SecureRandom.hex(3)}")
      }
      ActiveJob.perform_all_later(jobs)
      sleep(tick_ms / 1000.0)
    end
  end

  private

  # Pick i in 1..n with P(i) = i / sum(1..n). Linear scan — fine for
  # the few-hundred-account case this is aimed at.
  def weighted_sample(n, total_weight)
    r   = rand(total_weight)
    sum = 0
    (1..n).each do |id|
      sum += id
      return id if r < sum
    end
    n
  end
end
