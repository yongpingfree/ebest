class CreateThirdPartyCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :third_party_categories do |t|

      t.belongs_to :web_category
      t.string :third_party_id, index: true
      t.integer :third_party_type, comment: "第三方平台类型: 1: shopline, 2: aliexpress"

      t.timestamps
    end

    add_index :third_party_categories, [:web_category_id, :third_party_type], unique: true, name: "index_third_party_categories_on_category_id_and_type"
  end
end
