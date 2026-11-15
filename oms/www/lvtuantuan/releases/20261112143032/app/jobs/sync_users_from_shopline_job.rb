# frozen_string_literal: true

class SyncUsersFromShoplineJob < ApplicationJob
  queue_as :shopline

  def perform(page_info = nil)
    # 现在没有peti_store，所以peti_store为false
    save_customers(page_info: page_info, peti_store: false)
  end

  def save_customers(page_info: nil, peti_store: false)
    store = if peti_store
      MagicBean::Store.find_by(name: "peti")
    else
      MagicBean::Store.find_by(name: "Sydney")
    end
    result = Shopline::Api.get_customers(page_info: page_info, peti_store: peti_store)
    if result["errors"].present?
      # 如果有错误返回，隔2s后重试，sleep会影响线程，但这里只是凌晨执行一遍，不会有什么影响
      sleep(2)
      save_customers(page_info: page_info, peti_store: peti_store)
      return
    end

    result["customers"].each do |customer|
      third_party_user = MagicBean::ThirdPartyUser.shopline.find_or_initialize_by(third_party_id: customer["id"])
      third_party_user.assign_attributes(
        email: customer["email"],
        first_name: customer["first_name"],
        last_name: customer["last_name"],
        nick_name: customer["nick_name"],
        gender: customer["gender"],
        phone: customer["phone"],
        total_spent: customer["total_spent"],
        orders_count: customer["orders_count"],
        note: customer["note"],
        state: customer["state"],
        store: store
      )
      third_party_user.save
    end

    headers = result.headers

    # 没link字段,说明已经请求到全部数据
    return if headers["Link"].blank?

    # 解析page_info
    # https://developer.shopline.com/docsv2/ec20/3cv5d7wpfgr6a8z5/gfzeraeezj4ff96u?version=v20241201
    target_link = headers["Link"].split(",").find { |link| link.include?("rel=\"next\"") }
    
    # 只有上一页的场景跳过
    return if target_link.blank?
    
    page_info = target_link.match(/<([^>]+)>; rel=\"([^"]+)\"/)[1].split("page_info=").last

    # 怀疑是page_info为空导致一直循环，这里先触发报错，方便排查错误
    raise "target_link: #{target_link}" if page_info.blank?
    
    SyncUsersFromShoplineJob.perform_later(page_info)
  end
end
