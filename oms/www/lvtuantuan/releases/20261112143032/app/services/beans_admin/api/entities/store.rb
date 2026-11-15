# frozen_string_literal: true
module BeansAdmin::API::Entities
  class Store < SimpleStore
    expose :default_au_suburb_id
    expose :default_au_suburb_name
    expose :au_suburbs, using: BeansAdmin::API::Entities::AuSuburb
    expose :au_suburb_names
    expose :au_suburb_ids
    expose :disabled, documentation: { type: Grape::API::Boolean, desc: "是否停用门店" }
    expose :admin_user_ids
    expose :admin_user_names
    expose :admin_users, using: BeansAdmin::API::Entities::AdminUser

    def default_au_suburb_name
      if object.default_au_suburb_id
        "#{object.default_au_suburb.name} #{object.default_au_suburb.postal_code}"
      end
    end

    def au_suburb_names
      object.au_suburbs.map do |suburb|
        "#{suburb.name} #{suburb.postal_code}"
      end.join(",")
    end

    def admin_user_names
      object.admin_users.map(&:name).join(",")
    end
  end
end
