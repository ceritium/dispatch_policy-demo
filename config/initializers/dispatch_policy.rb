# frozen_string_literal: true

Rails.application.config.to_prepare do
  DispatchPolicy.configure do |c|
    c.enabled         = ENV.fetch("DISPATCH_POLICY_ENABLED", "true") != "false"
    c.tick_sleep      = 1
    c.tick_sleep_busy = 0.1
    c.batch_size      = 100
    c.round_robin_quantum = 10
  end
end
