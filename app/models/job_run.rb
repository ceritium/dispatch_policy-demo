# frozen_string_literal: true

class JobRun < ApplicationRecord
  scope :recent, -> { order(id: :desc) }
end
