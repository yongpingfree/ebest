# frozen_string_literal: true

module BeansApp
  class API::V1::PagePopups < ::API
    # 弹窗 API

    namespace :page_popups, desc: "弹窗 API" do
      helpers do
        def sort_by
          "position asc"
        end

        def base_association
          # 默认拿首页弹窗
          scope = params[:scope].presence || "home"
          resource_class.where(store_id: [current_store_id, nil]).where("locales @> ARRAY[?]::varchar[]", [I18n.locale.to_s]).send(scope).active
        end

        def end_of_association_chain
          (current_user.nil? || current_user.new_user) ? base_association : base_association.without_for_new_user
        end
      end

      desc "获取弹窗", {
        success: API::Entities::PagePopup,
        is_array: true,
        skip_authentication: true
      }
      params do
        optional :scope, type: String, desc: "scope", values: MagicBean::PagePopup.page_types.keys
      end
      paginate
      get do
        # 获取用户默认地址，再查询对应的suburb_id
        default_address = current_user&.addresses&.where(is_default: true)&.first
        default_au_suburb_id = if default_address
          MagicBean::AuSuburb.ransack(name_case_insensitive_eq: default_address.city_name&.downcase, postal_code_eq: default_address.postal_code).result.first&.id
        else
          nil
        end

        response_collection(params: { default_au_suburb_id: default_au_suburb_id })
      end
    end
  end
end
