# frozen_string_literal: true

module BeansAdmin::Helpers
  module OrderPaidAnalysesHelper
    def start_date
      @start_date ||= (params[:date_range]&.first || Date.current)
    end

    def end_date
      @end_date ||= (params[:date_range]&.last || Date.current)
    end

    def analysis_time_range
      start_date.beginning_of_day..end_date.end_of_day
    end

    def analysis_data(channel)
      data = payment_type_arr.map do |payment_type|
        hash = paid_data(channel, payment_type).merge!(refund_data(channel, payment_type))
        hash.merge!({ gathering_in_yuan_sum: (hash[:final_amount_in_yuan_sum] - hash[:actual_refund_amount_in_yuan_sum]).round(2) })
      end
      format_data(data)
    end

    def order_collection(payment_type, channel = "mini_program", filter_statuses = [])
      MagicBean::Order.send(channel).where(payment_type: payment_type, created_at: analysis_time_range).where.not(paid_at: nil).ransack(status_in: filter_statuses, store_id_eq: params[:store_id_eq])
    end

    def after_sale_colletion(payment_type, channel = "mini_program", filter_statuses = [])
      MagicBean::AfterSale.includes(:order).where(channel: channel, payment_type: payment_type, created_at: analysis_time_range).ransack(status_in: filter_statuses, store_id_eq: params[:store_id_eq])
    end

    def payment_type_arr
      ["wechat", "credit_card", "union_pay", "omipay", "apple_pay", "cba_apple_pay", "cba_google_pay", "supay"]
    end

    def response_keys
      [:original_payment_in_yuan_sum, :payment_in_yuan_sum, :final_amount_in_yuan_sum, :service_amount_in_yuan_sum,
       :apply_refund_amount_in_yuan_sum, :actual_refund_amount_in_yuan_sum, :gathering_in_yuan_sum]
    end

    def paid_data(channel, payment_type)
      collection = order_collection(payment_type, channel)

      original_payment_in_cent_sum = collection.result.sum("CEILING(original_payment_in_cent #{payment_type == "wechat" ? "* aud_to_cny_exchange_rate" : "" })")
      payment_in_cent_sum = collection.result.sum("CEILING(payment_in_cent #{payment_type == "wechat" ? "* aud_to_cny_exchange_rate" : "" })")
      final_amount_in_cent = collection.result.sum("CEILING(final_amount_in_cent #{payment_type == "wechat" ? "* aud_to_cny_exchange_rate" : "" })")

      wechat_key = "CEILING(CEILING(payment_in_cent * wechat_service_percentage / 100.0) * aud_to_cny_exchange_rate)"
      omipay_key = "omipay_service_amount_dollar_in_cent"
      supay_key = "supay_service_amount_dollar_in_cent"
      credit_card_key = "CEILING(payment_in_cent * credit_card_service_percentage / 100.0)"
      service_amount_in_cent_sum = get_amount_by_key(collection, payment_type, wechat_key, credit_card_key, omipay_key, supay_key)

      {
        original_payment_in_yuan_sum: (original_payment_in_cent_sum/100.0).round(2),
        payment_in_yuan_sum: (payment_in_cent_sum/100.0).round(2),
        final_amount_in_yuan_sum: (final_amount_in_cent/100.0).round(2),
        service_amount_in_yuan_sum: (service_amount_in_cent_sum/100.0).round(2)
      }
    end

    def refund_data(channel, payment_type)
      direct_refund_collection = order_collection(payment_type, channel, [:apply_refund, :refunding, :trade_closed])
      actual_refund_collection = order_collection(payment_type, channel, [:trade_closed])
      after_sale_apply_refund_collection = after_sale_colletion(payment_type, channel)
      after_sale_actual_refund_collection = after_sale_colletion(payment_type, channel, [:finished])

      wechat_key = "CEILING((#{MagicBean::Order::DIRECT_REFUND_WECHAT_KEY}) * aud_to_cny_exchange_rate)"
      credit_card_key = MagicBean::Order::DIRECT_REFUND_CREDIT_CARD_KEY
      omipay_key = MagicBean::Order::DIRECT_REFUND_OMIPAY_KEY
      supay_key = MagicBean::Order::DIRECT_REFUND_SUPAY_KEY
      apply_refund_amount_in_cent_sum = get_amount_by_key(direct_refund_collection, payment_type, wechat_key, credit_card_key, omipay_key, supay_key)
      actual_refund_amount_in_cent_sum = get_amount_by_key(actual_refund_collection, payment_type, wechat_key, credit_card_key, omipay_key, supay_key)

      after_sale_wechat_key = "CEILING(#{MagicBean::AfterSale::REFUND_KEY} * orders.aud_to_cny_exchange_rate)"
      after_sale_credit_card_key = MagicBean::AfterSale::REFUND_KEY
      after_sale_omipay_key = MagicBean::AfterSale::REFUND_KEY
      after_sale_supay_key = MagicBean::AfterSale::REFUND_KEY
      after_sale_apply_refund_sum = get_amount_by_key(after_sale_apply_refund_collection, payment_type, after_sale_wechat_key, after_sale_credit_card_key, after_sale_omipay_key, after_sale_supay_key)
      after_sale_actual_refund_sum = get_amount_by_key(after_sale_actual_refund_collection, payment_type, after_sale_wechat_key, after_sale_credit_card_key, after_sale_omipay_key, after_sale_supay_key)

      {
        apply_refund_amount_in_yuan_sum: ((apply_refund_amount_in_cent_sum + after_sale_apply_refund_sum)/100.0).round(2),
        actual_refund_amount_in_yuan_sum: ((actual_refund_amount_in_cent_sum + after_sale_actual_refund_sum)/100.0).round(2)
      }
    end

    def get_amount_by_key(collection, payment_type, wechat_key, credit_card_key, omipay_key, supay_key)
      if payment_type == "wechat"
        collection.result.sum(wechat_key)
      elsif payment_type == "omipay"
        collection.result.sum(omipay_key)
      elsif payment_type == "supay"
        collection.result.sum(supay_key)
      else
        collection.result.sum(credit_card_key)
      end
    end

    def format_data(data)
      result = []
      response_keys.each do |key|
        hash = { "title" => title(key) }

        data.each_with_index do |d, i|
          hash[payment_type_arr[i]] = d[key]
        end
        result << hash
      end
      result
    end

    def title(name)
      case name.to_s
      when "original_payment_in_yuan_sum"
        "订单总金额"
      when "payment_in_yuan_sum"
        "订单应付金额"
      when "final_amount_in_yuan_sum"
        "订单实收金额"
      when "service_amount_in_yuan_sum"
        "订单手续费"
      when "apply_refund_amount_in_yuan_sum"
        "申请退款金额"
      when "actual_refund_amount_in_yuan_sum"
        "实际退款金额"
      when "gathering_in_yuan_sum"
        "合计收款金额"
      end
    end
  end
end
