# frozen_string_literal: true

class SaveLiveCommentsJob < ApplicationJob
  queue_as :low_priority

  def perform(comment_data)
    comment_data[:commented_at] = Time.at(comment_data[:commented_at])
    MagicBean::LiveComment.create!(comment_data)
  end
end
