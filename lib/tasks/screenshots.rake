namespace :screenshots do
  desc "Capture demo screenshots into screenshots/ for the README."
  task capture: :environment do
    require "capybara"
    require "capybara/dsl"
    require "selenium-webdriver"

    Capybara.register_driver(:headless_chrome_retina) do |app|
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument("--headless=new")
      options.add_argument("--window-size=1440,900")
      options.add_argument("--force-device-scale-factor=2")
      options.add_argument("--no-sandbox")
      options.add_argument("--disable-gpu")
      options.add_argument("--disable-dev-shm-usage")
      Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
    end

    Capybara.default_driver        = :headless_chrome_retina
    Capybara.app                   = Rails.application
    Capybara.server                = :puma, { Silent: true }
    Capybara.default_max_wait_time = 10

    seed_demo_state

    out_dir = Rails.root.join("screenshots")
    FileUtils.mkdir_p(out_dir)

    session = Capybara::Session.new(:headless_chrome_retina, Rails.application)

    save = lambda do |name|
      path = out_dir.join("#{name}.png")
      session.save_screenshot(path)
      puts "  saved #{name}.png"
    end

    puts "Capturing demo pages..."

    session.visit "/"
    save.call("home")

    session.visit "/stats"
    save.call("stats")

    session.visit "/dispatch_policy"
    save.call("admin-index")

    [ EmailJob, ReportJob, TenantWorkJob, MaintenanceJob ].each do |klass|
      policy_name = klass.resolved_dispatch_policy.name
      watched     = pick_watched_partitions(policy_name)
      query       = watched.any? ? "?watch=#{watched.join(',')}" : ""

      session.visit "/dispatch_policy/policies/#{CGI.escape(policy_name)}#{query}"
      save.call("admin-policy-#{policy_name.parameterize}")
    end

    session.quit
    puts "Done. Screenshots are in screenshots/."
  end

  # Pre-flight: stage jobs through DispatchPolicy, run the tick to admit
  # them, then drain the GoodJob queue inline. This populates
  # PartitionObservation (sparklines), PartitionInflightCount, and StagedJob
  # completed_at — the same flow a real worker would produce, just compressed
  # into one rake call. After the drain we leave a handful of fresh jobs
  # staged to give the admin's "pending" counters something to show.
  def seed_demo_state
    puts "Seeding demo state..."

    DispatchPolicy::StagedJob.delete_all
    DispatchPolicy::PartitionObservation.delete_all
    DispatchPolicy::PartitionInflightCount.delete_all
    JobRun.delete_all

    %w[A B C].each do |account|
      6.times { |i| EmailJob.perform_later(account_id: account, subject: "demo-#{i}") }
      4.times { |i| ReportJob.perform_later(account_id: account, report_id: "r-#{i}") }
    end

    %w[acc_1 acc_3 acc_7 acc_15 acc_42].each do |account|
      rand(2..5).times { TenantWorkJob.perform_later(account_id: account, task: "report") }
    end

    4.times { |i| MaintenanceJob.perform_later(name: "vacuum-#{i}") }

    drain_through_dispatch_policy

    %w[A B C].each do |account|
      3.times { EmailJob.perform_later(account_id: account, subject: "queued-#{rand(1_000)}") }
    end
    4.times { TenantWorkJob.perform_later(account_id: "acc_#{rand(1..50)}", task: "queued") }
  end

  def drain_through_dispatch_policy
    policies = [ EmailJob, ReportJob, TenantWorkJob, MaintenanceJob ]
                 .map { |k| k.resolved_dispatch_policy.name }

    4.times do
      policies.each { |name| DispatchPolicy::Tick.run(policy_name: name) }
      GoodJob.perform_inline
      sleep 0.1
    end
  end

  # Pre-select 2-3 partitions per policy via the URL ?watch= param so the
  # "watched" section of the admin renders with sparklines populated.
  def pick_watched_partitions(policy_name)
    DispatchPolicy::PartitionObservation
      .where(policy_name: policy_name)
      .group(:partition_key)
      .order(Arel.sql("COUNT(*) DESC"))
      .limit(3)
      .pluck(:partition_key)
      .compact
  rescue StandardError
    []
  end
end
