# frozen_string_literal: true

class AddStoreIdToPromoCodes < ActiveRecord::Migration[5.2]
  def change
    add_column :promo_codes, :store_id, :integer

    say_with_time "update promo_codes store_id" do
      MagicBean::PromoCode.reset_column_information

      MagicBean::PromoCodeTemplate.includes(:promo_codes).find_each do |template|
        template.promo_codes.update_all(store_id: template.store_id)
      end
    end
  end
end
