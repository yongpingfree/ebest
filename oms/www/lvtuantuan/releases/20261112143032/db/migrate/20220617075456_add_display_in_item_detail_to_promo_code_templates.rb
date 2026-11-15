# frozen_string_literal: true

class AddDisplayInItemDetailToPromoCodeTemplates < ActiveRecord::Migration[5.2]
  def change
    add_column :promo_code_templates, :display_in_item_detail, :boolean, default: false
  end
end
