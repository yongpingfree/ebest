# frozen_string_literal: true

class AddNotEligibleForFreeGiftToGiftCardTemplates < ActiveRecord::Migration[5.2]
  def change
    add_column :gift_card_templates, :not_eligible_for_free_gift, :boolean, default: true, comment: "是否不参与满赠, 默认不参与"
    add_column :gift_card_coupons, :not_eligible_for_free_gift, :boolean, default: true, comment: "是否不参与满赠, 默认不参与"

    # 旧数据全部设置为参与满赠
    say_with_time "init gift cards not_eligible_for_free_gift" do
      MagicBean::GiftCardTemplate.reset_column_information
      MagicBean::GiftCardCoupon.reset_column_information
      MagicBean::GiftCardTemplate.update_all(not_eligible_for_free_gift: false)
      MagicBean::GiftCardCoupon.update_all(not_eligible_for_free_gift: false)
    end
  end
end
