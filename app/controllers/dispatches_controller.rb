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

    if batch
      jobs = count.times.map { |i| klass.new(**varied_args(args, i)) }
      ActiveJob.perform_all_later(jobs)
    else
      count.times do |i|
        kw = varied_args(args, i)
        if wait_until
          klass.set(wait_until: wait_until).perform_later(**kw)
        else
          klass.perform_later(**kw)
        end
      end
    end
  end

  # Make each enqueue unique so dedupe doesn't collapse the whole burst into
  # one. Picks the kwarg that's part of the dedupe key per job class.
  def varied_args(args, i)
    case
    when args.key?(:subject)   then args.merge(subject: "#{args[:subject]} ##{i}")
    when args.key?(:report_id) then args.merge(report_id: "#{args[:report_id]}-#{i}")
    when args.key?(:task)      then args.merge(task: "#{args[:task]}-#{i}")
    when args.key?(:name)      then args.merge(name: "#{args[:name]}-#{i}")
    else args
    end
  end
end
