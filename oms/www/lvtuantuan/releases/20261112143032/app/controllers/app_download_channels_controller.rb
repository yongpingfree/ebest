# frozen_string_literal: true

class AppDownloadChannelsController < ApplicationController
  def show
    @channel = MagicBean::AppDownloadChannel.find(params[:id])

    if request.user_agent.match /(iPad|iPhone|iPod)/
      @channel.increment!(:ios_views_count)
    elsif request.user_agent.match /(android|Android)/
      @channel.increment!(:android_views_count)
    else
      @channel.increment!(:other_views_count)
    end
  end
end
