# frozen_string_literal: true

class AddFreeShippingAmountInCentToFreightTemplates < ActiveRecord::Migration[5.2]
  def change
    add_column :freight_templates, :free_shipping_amount_in_cent, :integer, comment: "满金额免运费"
  end
end
