# frozen_string_literal: true

module ItemExcelParserConcern
  extend ActiveSupport::Concern

  class_methods do
    def get_channels(value_cn)
      arr = value_cn.to_s.split(/[;；]/).map(&:strip)

      arr.map do |str|
        case str
        when "APP"
          "app"
        when "小程序"
          "mini_program"
        when "Web网站"
          "web"
        when "shopline", "Shopline"
          "shopline"
        when "aliexpress", "AE", "Aliexpress"
          "aliexpress"
        else
          nil
        end
      end.compact.uniq
    end

    def get_delivery_type(value_cn)
      str = value_cn.to_s.strip

      case str
      when /[商家](配送|派送)/
        "merchant_delivery"
      when "自提"
        "self_pick"
      when "快递", "邮寄"
        "express"
      else
        nil
      end
    end

    def get_storage_method_key(value_cn)
      str = value_cn.to_s.strip

      case str
      when "常温"
        :room_temp_storage
      when "冷藏"
        :refrigerated_storage
      when "冷冻"
        :frozen_storage
      when "其他"
        :other_storage
      when "/"
        :blank_storage
      else
        nil
      end
    end

    def get_marketing_mode_key(value_cn)
      str = value_cn.to_s.strip

      case str
      when "寄售"
        "consign_for_sale"
      when "平台"
        "platform"
      when "自营"
       "self_support"
      else
        nil
      end
    end

    def get_boolean_value(value_cn)
      str = value_cn.to_s.strip

      case str
      when "是"
        true
      when "否"
        false
      else
        nil
      end
    end

    def get_image_url(value)
      str = value.to_s.strip

      if str.present?
        "https://#{Rails.application.credentials.dig(Rails.env.to_sym, :aws)[:cdn_host]}/items/#{str}"
      else
        nil
      end
    end

    def get_weekday_value(value_cn)
      str = value_cn.to_s.strip

      case str
      when "周一"
        "1"
      when "周二"
        "2"
      when "周三"
        "3"
      when "周四"
        "4"
      when "周五"
        "5"
      when "周六"
        "6"
      when "周日"
        "0"
      end
    end
  end
end
