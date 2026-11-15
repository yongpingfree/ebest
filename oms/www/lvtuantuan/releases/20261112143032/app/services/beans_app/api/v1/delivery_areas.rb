# frozen_string_literal: true

module BeansApp
  class API::V1::DeliveryAreas < ::API

    namespace :delivery_areas, desc: "送货上门区域API" do
      helpers do
        def default_order
          if params[:current_location].present?
            "distance ASC"
          else
            super
          end
        end

        def end_of_association_chain
          if params[:current_location].present?
            resource_class.near(params[:current_location], 30000, units: :km)
          else
            super
          end
        end
      end

      desc "送货上门区域列表", {
        success: API::Entities::DeliveryArea,
        is_array: true,
        skip_authentication: true
      }
      paginate
      params do
        optional :keyword, as: :suburb_or_postal_code_cont, type: String, desc: "送货上门区域"
        optional :current_location, type: Array[String], desc: "当前地址经纬度，例如：[-34.11,143.22]，传了这个参数即会按照距离近优先排序"
      end
      get do
        params[:store_id_eq] = current_store_id
        authorize_and_response_collection
      end

      desc "配送信息搜索"
      params do
        requires :postal_code, type: String, desc: "邮编"
        requires :suburb, type: String
      end
      get "search" do
        delivery_area = MagicBean::DeliveryArea.ransack(postal_code_eq: params[:postal_code]&.strip || -1, suburb_case_insensitive_eq: params[:suburb]&.strip&.downcase || -1).result.first
        store = delivery_area&.au_suburb&.store
        delivery_time = delivery_area&.delivery_time
        response_error(I18n.t("grape.delivery_areas.not_delivery")) if delivery_area.blank? || store.blank? || delivery_time.blank?

        time, limit = Time.current, 0
        store_site_config = store.site_config
        selected_cot = store_site_config.format_cutoff_time.reject { |t| t[:time] <= time.strftime("%H:%M") }.first
        if selected_cot.blank?
          selected_cot = store_site_config.format_cutoff_time.first
          time += 1.day
        end
        available_date = ("#{time.strftime("%Y-%m-%d")} #{selected_cot[:time]}".in_time_zone + (selected_cot[:time_kind] == "next_day" ? 1 : 0).days).to_date

        # 忽略delivery_time不设置weekdays的情况，目前生成环境都是有设置的
        tmp_not_delivery_dates = MagicBean::Item::NOT_DELIVERY_DAYS
        tmp_not_delivery_dates += ["2023-06-12"] if store&.id == 2

        loop do
          wday = available_date.wday.to_s
          if available_date.to_s.in?(tmp_not_delivery_dates) || !wday.in?(delivery_time.weekdays)
            limit += 1
            available_date += 1.day
          else
            break
          end
          break if limit > 7
        end

        # 先查特殊区域运费模板是否有记录
        target_template = nil
        # 特殊地区模板才会设置地区，所以au_suburb.freight_templates拿到的都是特殊模板
        # 一个地区可能存在于多个特殊模板中，所以需要根据用户所在门店来查
        delivery_area.au_suburb.freight_templates.includes(:default_freight_template).where(store_id: current_store_id || store&.id).order(:id).each do |exceptional_template|
          # 现在特殊模板的delivery_type都是merchant_delivery, 需要拿默认模板delivery_type的的才行
          if exceptional_template.default_freight_template.merchant_delivery?
            target_template = exceptional_template
            break
          end
        end

        # 如果设置了特殊地区就以特殊地区免邮为准，反之以默认模板免邮为准
        target_template = MagicBean::DefaultFreightTemplate.where(store_id: current_store_id || store&.id).merchant_delivery.order(:id).first unless target_template

        if target_template
          free_shipping_text = I18n.t("grape.orders.free_shipping_text", amount: target_template.send("#{ebest_channel}_free_shipping_amount_in_yuan_num"))
          # 以1kg为基准计算未满免运金额的运费
          shipping_text = if target_template.first_kg_charge_in_cent.to_i.positive?
            I18n.t("grape.orders.shipping_text", amount: target_template.send("#{ebest_channel}_free_shipping_amount_in_yuan_num"), freight: target_template.first_kg_charge_in_yuan, long_distance_fee: target_template.long_distance_fee_in_yuan)
          else
            ""
          end            
        else
          free_shipping_text, shipping_text = "", ""
        end

        {
          suburb: params[:suburb],
          postal_code: params[:postal_code],
          available_date: available_date,
          weekdays: delivery_time.weekdays,
          time_period: delivery_time.time_period.join(", "),
          free_shipping_text: free_shipping_text,
          shipping_text: shipping_text
        }
      end

      desc "获取App不同配送方式免运金额", {
        skip_authentication: true
      }
      params do
        requires :postal_code, type: String, desc: "邮编"
        requires :suburb, type: String
        optional :ae_drop_shipper_eq, type: Boolean, default: false, desc: "是否跨境购"
      end
      get "free_shipping_amount" do
        # 凑单需要计算商品的免运金额，现在每个门店每种配送只会有一个运费模板
        free_shipping_amount_hash = {}

        MagicBean::FreightTemplate.delivery_types.keys.each do |delivery_type|
          default_freight_template = MagicBean::DefaultFreightTemplate.send(delivery_type).where(store_id: current_store_id, ae_drop_shipper: params[:ae_drop_shipper_eq]).first
          exceptional_freight_template = default_freight_template&.exceptional_freight_templates&.ransack(
            au_suburbs_postal_code_eq: params[:postal_code],
            au_suburbs_name_case_insensitive_eq: params[:suburb]&.downcase
          )&.result&.first
          free_shipping_amount =
            if exceptional_freight_template
              { app_free_shipping_amount_in_cent: exceptional_freight_template.app_free_shipping_amount_in_cent, app_free_shipping_amount_in_yuan: exceptional_freight_template.app_free_shipping_amount_in_yuan }
            else
              { app_free_shipping_amount_in_cent: default_freight_template&.app_free_shipping_amount_in_cent, app_free_shipping_amount_in_yuan: default_freight_template&.app_free_shipping_amount_in_yuan }
            end
           
          free_shipping_amount_hash[delivery_type] = free_shipping_amount
        end

        free_shipping_amount_hash
      end
    end
  end
end
