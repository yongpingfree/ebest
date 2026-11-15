# frozen_string_literal: true

class AddAeFreeShippingThresholdToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :ae_free_shipping_threshold_in_cent, :integer, default: 0, comment: "AE 免运费门槛"
    add_column :items, :ae_shipping_info_last_updated_date, :date, comment: "AE商品物流信息最后更新日期"
  end
end
