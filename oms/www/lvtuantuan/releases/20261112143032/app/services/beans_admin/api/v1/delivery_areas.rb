# frozen_string_literal: true

module BeansAdmin
  class API::V1::DeliveryAreas < ::API

    namespace :delivery_areas, desc: "送货上门区域 API" do

      helpers do
        def permitted_params
          [:suburb, :postal_code, :latitude, :longitude, :au_suburb_id, :delivery_time_id, :same_day_delivery_time_id]
        end

        def includes
          [:delivery_time]
        end
      end

      desc "送货上门区域列表", {
        success: API::Entities::DeliveryArea,
        is_array: true
      }
      paginate
      params do
        optional :keyword, as: :suburb_or_postal_code_cont, type: String, desc: "区域或邮编查询"
      end
      get do
        authorize_and_response_collection
      end

      desc "新增送货上门区域", {
        success: API::Entities::DeliveryArea
      }
      params do
        requires :all, using: API::Entities::DeliveryArea.documentation.slice(:suburb, :postal_code)
        optional :all, using: API::Entities::DeliveryArea.documentation.slice(:latitude, :longitude, :google_place_id)
      end
      post do
        authorize_and_create_resource
      end

      desc "配送信息搜索"
      params do
        requires :au_suburb_id, type: Integer
      end
      get "freight_search" do
        raise CanCan::AccessDenied unless current_user.permissions.include?("freight_search")

        au_suburb = MagicBean::AuSuburb.find_by(id: params[:au_suburb_id])

        delivery_area = MagicBean::DeliveryArea.ransack(postal_code_eq: au_suburb&.postal_code || -1, suburb_case_insensitive_eq: au_suburb&.name&.strip&.downcase || -1).result.first
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
          free_shipping_text = I18n.t("grape.orders.free_shipping_text", amount: target_template.app_free_shipping_amount_in_yuan_num)
          # 以1kg为基准计算未满免运金额的运费
          shipping_text = if target_template.first_kg_charge_in_cent.to_i.positive?
            I18n.t("grape.orders.shipping_text", amount: target_template.app_free_shipping_amount_in_yuan_num, freight: target_template.first_kg_charge_in_yuan, long_distance_fee: target_template.long_distance_fee_in_yuan)
          else
            ""
          end            
        else
          free_shipping_text, shipping_text = "", ""
        end

        [{
          suburb: au_suburb&.name,
          postal_code: au_suburb&.postal_code,
          available_date: available_date,
          weekdays: delivery_time.weekdays,
          time_period: delivery_time.time_period.join(", "),
          free_shipping_text: free_shipping_text,
          shipping_text: shipping_text
        }]
      end

      route_param :id do
        desc "送货上门区域详情", {
          success: API::Entities::DeliveryArea
        }
        get do
          authorize_and_response_resource
        end

        desc "更新商品送货上门区域", {
          success: API::Entities::DeliveryArea
        }
        params do
          optional :all, using: API::Entities::DeliveryArea.documentation.slice(:suburb, :latitude, :longitude, :postal_code, :google_place_id)
        end
        put do
          authorize_and_update_resource
        end

        desc "删除商品送货上门区域", {
          detail: <<-NOTES.strip_heredoc
            ```json
            {
              code: 200,
              message: "ok"
            }
            ```
          NOTES
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
