# frozen_string_literal: true

class DispatchesController < ApplicationController
  def create
    kind       = params[:kind].to_s
    count      = params[:count].to_i.clamp(1, 500)
    account_id = params[:account_id].presence || "A"
    subject    = params[:subject].presence || "Daily update"
    task       = params[:task].presence || "process"
    wait_sec   = params[:wait_seconds].to_i
    batch      = params[:batch] == "1"

    job_class, args = case kind
                      when "email"
                        [ EmailJob, { account_id: account_id, subject: subject } ]
                      when "report"
                        [ ReportJob, { account_id: account_id, report_id: SecureRandom.hex(4) } ]
                      when "tenant_work"
                        [ TenantWorkJob, { account_id: account_id, task: task } ]
                      when "webhook"
                        [ WebhookDeliveryJob, { account_id: account_id } ]
                      when "maintenance"
                        [ MaintenanceJob, { name: task } ]
                      else
                        redirect_to(root_path, alert: "Unknown kind #{kind.inspect}") and return
                      end

    enqueue_jobs(job_class, count, args, wait_sec, batch)

    message = "Enqueued #{count} #{job_class.name}#{batch ? ' (batch)' : ''} " \
              "for account=#{account_id}#{wait_sec.positive? ? " (wait #{wait_sec}s)" : ''}"

    respond_to do |format|
      format.html { redirect_to root_path, notice: message }
      format.json { render json: { notice: message } }
    end
  end

  private

  def enqueue_jobs(klass, count, args, wait_sec, batch)
    wait_until = wait_sec.positive? ? Time.current + wait_sec : nil
    # Per-request salt so repeated submits don't collide with each other on
    # the dedupe index. Each row inside this submit is still distinct via i.
    salt = SecureRandom.hex(3)

    if batch
      jobs = count.times.map { |i| klass.new(**varied_args(args, i, salt)) }
      ActiveJob.perform_all_later(jobs)
    else
      count.times do |i|
        kw = varied_args(args, i, salt)
        if wait_until
          klass.set(wait_until: wait_until).perform_later(**kw)
        else
          klass.perform_later(**kw)
        end
      end
    end
  end

  # Suffix the dedupe-bearing field with `<salt>-<i>` so each submit produces
  # a fresh set of keys. To *see* dedupe in action, pass an explicit subject
  # the same twice — when the first pending row is still around, a batch
  # re-submit with the same (account, subject) collapses.
  def varied_args(args, i, salt)
    suffix = "#{salt}-#{i}"
    case
    when args.key?(:subject)   then args.merge(subject: "#{args[:subject]} (#{suffix})")
    when args.key?(:report_id) then args.merge(report_id: "#{args[:report_id]}-#{suffix}")
    when args.key?(:task)      then args.merge(task: "#{args[:task]}-#{suffix}")
    when args.key?(:name)      then args.merge(name: "#{args[:name]}-#{suffix}")
    else args
    end
  end
end
