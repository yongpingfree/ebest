# frozen_string_literal: true

module BeansApp
  class API::V1::MultiLangConfigs < ::API
    namespace :multi_lang_configs, desc: "多语系内容 API" do
      desc "获取配置", {
        skip_authentication: true,
        success: API::Entities::MultiLangConfig
      }
      params do
        optional :order_id, type: Integer, desc: "订单ID"
      end
      get do
        config = MagicBean::MultiLangConfig.config(current_store_id, I18n.locale, :app)
        order = current_user&.orders&.find_by id: params[:order_id]
        present config, with: API::Entities::MultiLangConfig, order: order
      end
    end
  end
end
