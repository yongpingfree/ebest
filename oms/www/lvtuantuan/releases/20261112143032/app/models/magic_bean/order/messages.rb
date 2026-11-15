# frozen_string_literal: true

class MagicBean::Order
  # 订单短信相关
  module Messages
    extend ActiveSupport::Concern

    # 配置中的自提订单下单消息通知内容
    def normal_order_paid_message
      message = admin_multi_lang_config.order_paid_message&.gsub("{{no}}", no.last(4))
                  &.gsub("{{delivery_type}}", I18n.t("activerecord.attributes.magic_bean/order.delivery_types.#{delivery_type}"))
                  &.gsub("{{payment_total}}", actual_amount_for_display)
      if merchant_delivery? || self_pick?
        message&.gsub("{{merchant_delivery_date}}", "#{delivery_date}")
      else
        message&.gsub("{{merchant_delivery_date}}", "")
      end
    end

    def normal_order_paid_notification
      message = admin_multi_lang_config.order_paid_notification&.gsub("{{no}}", no.last(4))
                  &.gsub("{{delivery_type}}", I18n.t("activerecord.attributes.magic_bean/order.delivery_types.#{delivery_type}"))
                  &.gsub("{{payment_total}}", actual_amount_for_display)

      if merchant_delivery? || self_pick?
        message&.gsub("{{merchant_delivery_date}}", "#{delivery_date}")
      else
        message&.gsub("{{merchant_delivery_date}}", "")
      end
    end

    def live_top_order_paid_message
      message = admin_multi_lang_config.live_top_order_paid_message&.gsub("{{no}}", no.last(4))
                  &.gsub("{{payment_total}}", actual_amount_for_display)
      if merchant_delivery? || self_pick?
        message&.gsub("{{merchant_delivery_date}}", "#{delivery_date}")
      else
        message&.gsub("{{merchant_delivery_date}}", "")
      end
    end

    def live_top_order_paid_notification
      message = admin_multi_lang_config.live_top_order_paid_notification&.gsub("{{no}}", no.last(4))
                  &.gsub("{{payment_total}}", actual_amount_for_display)

      if merchant_delivery? || self_pick?
        message&.gsub("{{merchant_delivery_date}}", "#{delivery_date}")
      else
        message&.gsub("{{merchant_delivery_date}}", "")
      end
    end

    def live_top_order_confirm_message
      message = admin_multi_lang_config.live_top_order_confirm_message&.gsub("{{no}}", no.last(4))

      if merchant_delivery? || self_pick?
        message&.gsub("{{merchant_delivery_date}}", "#{delivery_date}")
      else
        message&.gsub("{{merchant_delivery_date}}", "")
      end
    end

    def live_top_order_confirm_notification
      message = admin_multi_lang_config.live_top_order_confirm_notification&.gsub("{{no}}", no.last(4))

      if merchant_delivery? || self_pick?
        message&.gsub("{{merchant_delivery_date}}", "#{delivery_date}")
      else
        message&.gsub("{{merchant_delivery_date}}", "")
      end
    end

    def ae_order_failed_and_refund_notice
      admin_multi_lang_config.ae_order_failed_and_refund_notice&.gsub("{{no}}", no)
    end

    # 订单完成积分通知
    def reward_order_finished_integral_notification
      "订单 #{targetable&.no} 交易完成，奖励积分#{integral.abs}"
    end

    def assign_coupon_notification
      Globalize.with_locale(user.locale) do
        I18n.t("attributes.coupon_template.assign_coupon_notification", title: coupon_template_title, locale: user.locale)
      end
    end

    def coupon_expire_notification(user, titles)
      I18n.t("attributes.coupon_template.coupon_expire_notification", titles: titles, locale: user.locale)
    end

    # 部分缺货短信通知
    # TODO 解决 rollback 的问题, 因为短信是在事务中，但短信并不能被rollback
    def send_order_part_stockout_message(after_sales_order_items)
      stockout_items_text = after_sales_order_items.first(3).map { |item| "#{item[:order_item].human_title} x #{item[:quantity]}" }.join(";")

      message = admin_multi_lang_config.order_partly_stockout_message&.gsub("{{no}}", no.last(4))
        &.gsub("{{delivery_type}}", I18n.t("activerecord.attributes.magic_bean/order.delivery_types.#{delivery_type}"))
        &.gsub("{{stockout_items}}", stockout_items_text)

      unless user_member_mobile.eql?(receiver_tel_number)
        SmsJob.perform_later(receiver_tel_number, message)
      end
      SmsJob.perform_later(user_member_mobile, message)
    end

    def send_order_part_stockout_notification(after_sales_order_items)
      stockout_items_text = after_sales_order_items.first(3).map { |item| "#{item[:order_item].human_title} x #{item[:quantity]}" }.join(";")

      message = admin_multi_lang_config.order_partly_stockout_notification&.gsub("{{no}}", no.last(4))
        &.gsub("{{delivery_type}}", I18n.t("activerecord.attributes.magic_bean/order.delivery_types.#{delivery_type}"))
        &.gsub("{{stockout_items}}", stockout_items_text)

      return if message.blank?

      user.app_text_messages.create(
        title: I18n.t("activerecord.attributes.magic_bean/app_text_message.titles.order_partly_stockout_notification"),
        content: message,
        kind: :customer_service
      )
    end

    def send_admin_create_after_sale_message(after_sales_order_items, after_sales_return_type)
      items_text = after_sales_order_items.first(3).map { |item| "#{item.order_item.human_title} x #{item.quantity}" }.join(";")

      template_key = case after_sales_return_type.to_s
                     when "integral"
                       "admin_create_after_sale_integral_notification"
                     when "coupon"
                       "admin_create_after_sale_coupon_notification"
                     else
                       "admin_create_after_sale_message"
                     end

      message = admin_multi_lang_config.send(template_key)&.gsub("{{no}}", no.last(4))
                  &.gsub("{{after_sales_items}}", items_text)

      unless user_member_mobile.eql?(receiver_tel_number)
        SmsJob.perform_later(receiver_tel_number, message)
      end
      SmsJob.perform_later(user_member_mobile, message)
    end

    def send_admin_create_after_sale_notification(after_sales_order_items, after_sales_return_type)
      items_text = after_sales_order_items.first(3).map { |item| "#{item.order_item.human_title} x #{item.quantity}" }.join(";")

      template_key = case after_sales_return_type.to_s
                     when "integral"
                       "admin_create_after_sale_integral_notification"
                     when "coupon"
                       "admin_create_after_sale_coupon_notification"
                     else
                       "admin_create_after_sale_notification"
                     end

      message = admin_multi_lang_config.send(template_key)&.gsub("{{no}}", no.last(4))
                  &.gsub("{{after_sales_items}}", items_text)

      return if message.blank?

      user.app_text_messages.create(
        title: I18n.t("activerecord.attributes.magic_bean/app_text_message.titles.order_after_sale_refund_notification"),
        content: message,
        kind: :customer_service
      )
    end

    def send_delivery_datetime_sms_and_notification
      original_locale = I18n.locale
      I18n.locale = user_locale

      send_delivery_datetime_sms
      send_delivery_datetime_notification

      I18n.locale = original_locale
    end

    # wms 更新了派送时间后推送一次短信给用户
    def send_delivery_datetime_sms
      return unless merchant_delivery?

      message = admin_multi_lang_config.merchant_delivery_time_updated_message
                  &.gsub("{{no}}", no.last(4))
                  &.gsub("{{delivery_track}}", delivery_track.to_s)
                  &.gsub("{{delivery_date}}", delivery_date.to_s)
                  &.gsub("{{prefer_time}}", prefer_time.to_s)

      return if message.blank?

      unless user_member_mobile.eql?(receiver_tel_number)
        SmsJob.perform_later(receiver_tel_number, message)
      end
      SmsJob.perform_later(user_member_mobile, message)
    end

    def send_delivery_datetime_notification
      return unless merchant_delivery?

      message = admin_multi_lang_config.merchant_delivery_time_updated_notification
                  &.gsub("{{no}}", no.last(4))
                  &.gsub("{{delivery_track}}", delivery_track.to_s)
                  &.gsub("{{delivery_date}}", delivery_date.to_s)
                  &.gsub("{{prefer_time}}", prefer_time.to_s)

      if message.present?
        user.app_text_messages.create(
          title: I18n.t("activerecord.attributes.magic_bean/app_text_message.titles.order_delivery_time_update_notification"),
          content: message,
          kind: :order_tracking
        )
      end
    end

    # TODO 解决 rollback 的问题, 因为短信是在事务中，但短信并不能被rollback
    def wms_dispatch_sms_message(logistic_no = nil, order_eta = nil, delivery_path = nil)
      return if logistic_no.blank? && !merchant_delivery?
      message =
        if self_pick?
          self_pick_up_code = delivery_path.to_s
          # 使用 delivery_track 保存自提码，自提订单前端不会显示物流入口
          self.update_column :delivery_track, self_pick_up_code if delivery_track.blank?

          admin_multi_lang_config.self_pick_order_dispatched_message
            &.gsub("{{no}}", no.last(4))&.gsub("{{opening_hours}}", self_pick_up.opening_hours.to_s)
            &.gsub("{{self_pick_up_code}}", self_pick_up_code)&.gsub("{{full_address}}", self_pick_up.full_address)
            &.gsub("{{delivery_date}}", delivery_date.to_s)&.gsub("{{prefer_time}}", prefer_time.to_s)
        elsif merchant_delivery?
          # 例如ETA是2023-12-04 14:24:03，那ETA文案为 {{2023-12-04 13:24 ~ 2023-12-04 15:24}}
          eta_text = order_eta.blank? ? "" : "#{(order_eta - 1.hour).strftime("%Y-%m-%d %H:%M")} ~ #{(order_eta + 1.hour).strftime("%Y-%m-%d %H:%M")}"
          
          admin_multi_lang_config.merchant_delivery_order_dispatched_message
            &.gsub("{{no}}", no.last(4))&.gsub("{{delivery_track}}", delivery_track.to_s)&.gsub("{{delivery_date}}", delivery_date.to_s)
            &.gsub("{{prefer_time}}", prefer_time.to_s)
            &.gsub("{{eta}}", eta_text)
        elsif express?
          admin_multi_lang_config.express_order_dispatched_message
            &.gsub("{{no}}", no.last(4))&.gsub("{{logistic_no}}", logistic_no.to_s)
        end

      return if message.blank?

      unless user_member_mobile.eql?(receiver_tel_number)
        SmsJob.perform_later(receiver_tel_number, message)
      end
      SmsJob.perform_later(user_member_mobile, message)
    end

    def wms_dispatch_notification(logistic_no = nil, eta = nil, delivery_path = nil)
      return if logistic_no.blank? && !merchant_delivery?

      message =
        if self_pick?
          self_pick_up_code = delivery_path.to_s
          # 使用 delivery_track 保存自提码，自提订单前端不会显示物流入口
          self.update_column :delivery_track, self_pick_up_code if delivery_track.blank?

          admin_multi_lang_config.self_pick_order_dispatched_notification
            &.gsub("{{no}}", no.last(4))&.gsub("{{opening_hours}}", self_pick_up.opening_hours.to_s)
            &.gsub("{{self_pick_up_code}}", self_pick_up_code)&.gsub("{{full_address}}", self_pick_up.full_address)
            &.gsub("{{delivery_date}}", delivery_date.to_s)&.gsub("{{prefer_time}}", prefer_time.to_s)
        elsif merchant_delivery?
          # 例如ETA是2023-12-04 14:24:03，那ETA文案为 {{2023-12-04 13:24 ~ 2023-12-04 15:24}}
          eta_text = eta.blank? ? "" : "#{(eta - 1.hour).strftime("%Y-%m-%d %H:%M")} ~ #{(eta + 1.hour).strftime("%Y-%m-%d %H:%M")}"

          admin_multi_lang_config.merchant_delivery_order_dispatched_notification
            &.gsub("{{no}}", no.last(4))&.gsub("{{delivery_track}}", delivery_track.to_s)&.gsub("{{delivery_date}}", delivery_date.to_s)
            &.gsub("{{prefer_time}}", prefer_time.to_s)
            &.gsub("{{eta}}", eta_text)
        elsif express?
          admin_multi_lang_config.express_order_dispatched_notification
            &.gsub("{{no}}", no.last(4))&.gsub("{{logistic_no}}", logistic_no.to_s)
        end

      if message.present?
        user.app_text_messages.create(
          title: I18n.t("activerecord.attributes.magic_bean/app_text_message.titles.order_delivery_notification"),
          content: message,
          kind: :order_tracking
        )
      end
    end

    # 订单下单后需要发手机短信通知
    def send_sms_message
      SmsJob.perform_later(user_member_mobile, normal_order_paid_message) if normal_order_paid_message.present?
    end

    def create_paid_app_text_message
      content = normal_order_paid_notification

      return if content.blank?

      user.app_text_messages.create(
        title: I18n.t("activerecord.attributes.magic_bean/app_text_message.titles.order_paid_notification", locale: user_locale),
        content: content,
        kind: :order_tracking
      )
    end

    def send_live_top_sms_message
      SmsJob.perform_later(user_member_mobile, live_top_order_paid_message) if live_top_order_paid_message.present?
    end

    def create_live_top_paid_app_text_message
      content = live_top_order_paid_notification

      return if content.blank?

      user.app_text_messages.create(
        title: I18n.t("activerecord.attributes.magic_bean/app_text_message.titles.order_paid_notification", locale: user_locale),
        content: content,
        kind: :order_tracking
      )
    end

    def send_live_top_confirm_sms_message
      SmsJob.perform_later(user_member_mobile, live_top_order_confirm_message) if live_top_order_confirm_message.present?
    end

    def create_live_top_confirm_app_text_message
      content = live_top_order_confirm_notification

      return if content.blank?

      user.app_text_messages.create(
        title: I18n.t("activerecord.attributes.magic_bean/app_text_message.titles.order_confirm_notification", locale: user_locale),
        content: content,
        kind: :order_tracking
      )
    end

    def create_ae_order_failed_and_refund_app_text_message
      content = ae_order_failed_and_refund_notice

      return if content.blank?

      user.app_text_messages.create(
        title: I18n.t("activerecord.attributes.magic_bean/app_text_message.titles.ae_order_failed_and_refund_notice", locale: user_locale),
        content: content,
        kind: :customer_service
      )
    end

    def send_order_paid_message
      return if virtual_delivery?

      if live_top_confirm?
        # 直播待审核订单需要用特殊消息模板
        create_live_top_paid_app_text_message
      else
        create_paid_app_text_message
      end
    end

    # 1. 用户没有填 email，仅发送短信
    # 2. 用户有填 email 且是在网站下单，仅发送邮件
    # 3. 用户有填 email 但不是在网站下单，同时发送短信和邮件
    def send_order_paid_notice
      if user.member&.email.blank?
        send_order_paid_message
      else
        send_order_paid_message unless web?
        enqueue_send_klaviyo_email_job("send_order_paid_email")
        # enqueue_send_sendgrid_email_job("paid_order")
      end
    end

    def send_live_top_order_confirm_message
      return if virtual_delivery?

      # send_live_top_confirm_sms_message
      create_live_top_confirm_app_text_message
    end

    def send_order_stockout_message
      message = admin_multi_lang_config.order_stockout_message&.gsub("{{no}}", no.last(4))
        &.gsub("{{delivery_type}}", I18n.t("activerecord.attributes.magic_bean/order.delivery_types.#{delivery_type}", locale: user_locale))

      unless user_member_mobile.eql?(receiver_tel_number)
        SmsJob.perform_later(receiver_tel_number, message)
      end
      SmsJob.perform_later(user_member_mobile, message)
    end

    def send_order_stockout_notification
      message = admin_multi_lang_config.order_stockout_notification&.gsub("{{no}}", no.last(4))
        &.gsub("{{delivery_type}}", I18n.t("activerecord.attributes.magic_bean/order.delivery_types.#{delivery_type}", locale: user_locale))

      return if message.blank?

      user.app_text_messages.create(
        title: I18n.t("activerecord.attributes.magic_bean/app_text_message.titles.order_stockout_notification", locale: user_locale),
        content: message,
        kind: :customer_service
      )
    end

    def send_order_stockout_email
      return if user_member.email.blank?

      enqueue_send_klaviyo_email_job("send_order_sellout_refunded_email")
      # enqueue_send_sendgrid_email_job("sellout_refunded_order")
    end

    def create_order_finished_integral_app_text_message
      content = reward_order_finished_integral_notification

      return if content.blank?

      member.user.app_text_messages.create(
        title: "积分发放通知",
        content: content,
        kind: :customer_service
      )
    end

    def create_assign_coupon_app_text_message
      content = assign_coupon_notification

      return if content.blank?

      user.app_text_messages.create(
        title: I18n.t("attributes.coupon_template.assign_coupon_notification_title", locale: user.locale),
        content: content,
        kind: :customer_service
      )
    end

    def create_coupon_expire_app_text_message(user, coupon_titles)
      return if coupon_titles.blank?

      content = coupon_expire_notification(user, coupon_titles)

      user.app_text_messages.create(
        title: I18n.t("attributes.coupon_template.coupon_expire_notification_title", locale: user.locale),
        content: content,
        kind: :customer_service
      )
    end
  end
end
