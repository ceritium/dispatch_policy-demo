# frozen_string_literal: true

class StormsController < ApplicationController
  def create
    num_accounts     = params[:num_accounts].to_i.clamp(1, 2_000)
    duration_seconds = params[:duration_seconds].to_i.clamp(1, 600)
    batch_size       = params[:batch_size].to_i.clamp(1, 200)

    StormJob.perform_later(
      num_accounts:     num_accounts,
      duration_seconds: duration_seconds,
      batch_size:       batch_size
    )

    message = "Storm started: #{num_accounts} accounts, #{duration_seconds}s, batch_size=#{batch_size}."
    respond_to do |format|
      format.html { redirect_to root_path, notice: message }
      format.json { render json: { notice: message } }
    end
  end
end
