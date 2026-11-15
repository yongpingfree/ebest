# frozen_string_literal: true

module BeansApp::API::Entities
  class SimpleOrderItem < ::CommonEntities::Model
    expose :quantity
    expose :image
    expose :price_in_cent
    expose :price_in_yuan
    expose :display_price_in_cent
    expose :display_price_in_yuan
    expose :amount_in_cent
    expose :amount_in_yuan
    expose :real_price_in_yuan
    expose :real_price_in_cent
    expose :real_amount_in_yuan
    expose :real_amount_in_cent
    expose :real_display_amount_in_cent
    expose :real_display_amount_in_yuan
    expose :strikethrough_price_in_cent
    expose :strikethrough_price_in_yuan
    expose :strikethrough_amount_in_cent
    expose :strikethrough_amount_in_yuan
    expose :weight_in_gram
    expose :properties_text
    expose :title
    expose :coupon_enabled
    expose :gift_card_enabled, documentation: { desc: "是否可使用礼品券" }
    expose :free_shipping
    expose :not_eligible_for_free_gift
    expose :item_id
    expose :sku_type
    expose :groups
    expose :comments, using: BeansApp::API::Entities::Comment
    expose :my_comment, as: :comment, using: BeansApp::API::Entities::Comment
    expose :refund_quantity
    expose :expiration_date
    expose :expiration_reminder_before_n_days
    expose :is_box_regulation

    def my_comment
      object.comments.select { |comment| comment.user_id == current_user.id }.first
    end
  end
end
