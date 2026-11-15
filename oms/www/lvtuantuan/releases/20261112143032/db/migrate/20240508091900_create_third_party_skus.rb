# frozen_string_literal: true

class CreateThirdPartySkus < ActiveRecord::Migration[5.2]
  def change    
    create_table :third_party_skus do |t|
      t.belongs_to :stock_keeping_unit
      t.string :third_party_id, index: true
      t.integer :third_party_type, comment: "第三方平台类型: 1: shopline, 2: aliexpress"
      t.string :third_party_inventory_item_id, comment: "库存id"

      t.timestamps
    end

    add_index :third_party_skus, [:stock_keeping_unit_id, :third_party_type], unique: true, name: "index_third_party_skus_on_sku_id_and_type"
  end
end
