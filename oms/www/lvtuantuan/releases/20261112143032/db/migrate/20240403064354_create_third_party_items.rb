class CreateThirdPartyItems < ActiveRecord::Migration[5.2]
  def change
    create_table :third_party_items do |t|
      t.belongs_to :item
      t.string :third_party_id, index: true
      t.integer :third_party_type, comment: "第三方平台类型: 1: shopline, 2: aliexpress"

      t.timestamps
    end

    add_index :third_party_items, [:item_id, :third_party_type], unique: true
  end
end
