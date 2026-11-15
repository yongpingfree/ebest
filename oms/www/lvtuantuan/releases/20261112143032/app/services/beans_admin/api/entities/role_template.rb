# frozen_string_literal: true

module BeansAdmin::API::Entities
  class RoleTemplate < ::CommonEntities::Model
    expose :name, documentation: { type: String, desc: "模板名称" }
    expose :permissions
    expose :permissions_cn

    def permissions_cn
      object.permissions.map do |permission|
        I18n.t("activerecord.models.#{permission.singularize}")
      end
    end
  end
end
