# frozen_string_literal: true

module BeansAdmin::API::Entities
  class AdminUser < SimpleAdminUser
    expose :permissions
    expose :permissions_cn
    expose :categories, documentation: { desc: "分类" }
    expose :can_not_update_sku_new_user_price?, as: :can_not_update_sku_new_user_price

    def permissions_cn
      object.permissions.map do |permission|
        I18n.t("activerecord.models.#{permission.singularize}")
      end
    end
  end
end
