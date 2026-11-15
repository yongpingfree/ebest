# frozen_string_literal: true

module BeansAdmin::API::Entities
  class GiftCardTemplate < ::CommonEntities::Model
    expose :denominations_in_yuan
    expose :denominations_in_cent
    expose :quantity
    expose :expired_at
    expose :purchaser
    expose :store_names
    expose :purpose
    expose :not_eligible_for_free_gift

    def store_names
      if object.store_ids.blank?
        "全部"
      elsif options[:stores_hash].present?
        object.store_ids.map { |store_id| options[:stores_hash][store_id.to_s] }.join(", ")
      else
        MagicBean::Store.where(id: object.store_ids).map(&:name).join(", ")
      end
    end
  end
end
