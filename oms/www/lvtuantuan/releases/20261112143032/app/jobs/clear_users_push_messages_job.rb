# frozen_string_literal: true

class ClearUsersPushMessagesJob < ApplicationJob
  queue_as :default

  # 每天凌晨清除45天以前的数据, 避免表数据过多
  def perform(*)
    MagicBean::UsersPushMessage.where("created_at < ?", Time.current - 45.days).delete_all
  end
end
