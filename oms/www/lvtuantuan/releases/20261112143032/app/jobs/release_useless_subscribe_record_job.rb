# frozen_string_literal: true

class ReleaseUselessSubscribeRecordJob < ApplicationJob
  queue_as :default

  def perform
    MagicBean::SubscribeRecord.find_each do |record|
      record.update(targetable: nil) if record.is_useless?
    end
  end
end
