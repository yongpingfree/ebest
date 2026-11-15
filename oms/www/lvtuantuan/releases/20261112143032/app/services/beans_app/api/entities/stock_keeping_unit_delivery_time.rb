# frozen_string_literal: true

module BeansApp::API::Entities
  class StockKeepingUnitDeliveryTime < ::CommonEntities::Model
    expose :earliest_delivery_start_at
    expose :earliest_delivery_end_at
    expose :earliest_delivery_wday
    expose :item_delivery_text
    expose :delivery_text

    def earliest_delivery_start_at
      return nil if item_earliest_delivery_time.blank?
      "#{item_earliest_delivery_time[:date]} #{item_earliest_delivery_time[:time].split("-").first}".in_time_zone
    end

    def earliest_delivery_end_at
      return nil if item_earliest_delivery_time.blank?
      "#{item_earliest_delivery_time[:date]} #{item_earliest_delivery_time[:time].split("-").last}".in_time_zone
    end

    def earliest_delivery_wday
      item_earliest_delivery_time[:wday]
    end

    def item_earliest_delivery_time
      @item_earliest_delivery_time ||= object.item.calculate_earliest_delivery_time(Time.current, current_postal_code, current_suburb)
    end

    def current_store_can_buy
      true
    end

    def item_delivery_text
      if current_store_can_buy
        return nil if item_earliest_delivery_time.blank?
        if Date.current == item_earliest_delivery_time[:date]
          delivery_time_text = english_locale? ? item_earliest_delivery_time[:date].strftime(date_strftime) : "#{I18n.t("grape.delivery.today")}（#{item_earliest_delivery_time[:date].strftime(date_strftime)}）"
          I18n.t("grape.delivery.estimated_text", delivery_time: delivery_time_text)
        elsif Date.tomorrow == item_earliest_delivery_time[:date]
          delivery_time_text = english_locale? ? item_earliest_delivery_time[:date].strftime(date_strftime) : "#{I18n.t("grape.delivery.tomorrow")}（#{item_earliest_delivery_time[:date].strftime(date_strftime)}）"
          I18n.t("grape.delivery.estimated_text", delivery_time: delivery_time_text)
        else
          i18n_name = object.item.ae_drop_shipper? ? "ae_choice_delivery_text" : "estimated_text"
          delivery_time_text = english_locale? ? item_earliest_delivery_time[:date].strftime(date_strftime) : item_earliest_delivery_time[:date].strftime(date_strftime)
          I18n.t("grape.delivery.#{i18n_name}", delivery_time: delivery_time_text)
        end
      end
    end

    def delivery_text
      if current_store_can_buy
        return "" if item_earliest_delivery_time.blank?
        date_alias = if Date.current == item_earliest_delivery_time[:date]
                       "#{I18n.t("grape.delivery.today")}（#{item_earliest_delivery_time[:date].strftime(date_strftime)}）"
                     elsif Date.tomorrow == item_earliest_delivery_time[:date]
                       "#{I18n.t("grape.delivery.tomorrow")}（#{item_earliest_delivery_time[:date].strftime(date_strftime)}）"
                     else
                       item_earliest_delivery_time[:date].strftime(date_strftime)
                     end

        time = item_earliest_delivery_time&.dig(:selected_cot, :time)
        time_text = english_locale? ? time_en_format(time) : time
        delivery_time_text = english_locale? ? item_earliest_delivery_time[:date].strftime(date_strftime) : date_alias

        if item_earliest_delivery_time[:use_merchant_delivery]
          I18n.t("grape.delivery.delivery_reach_text", time: time_text, delivery_time: delivery_time_text)
        else
          i18n_name = object.item.ae_drop_shipper? ? "ae_choice_delivery_text" : "express_delivery_text"
          I18n.t("grape.delivery.#{i18n_name}", time: time_text, delivery_time: delivery_time_text)
        end              
      else
        I18n.t("grape.delivery.no_delivery")
      end
    end
  end
end
