# frozen_string_literal: true

class CreateThirdPartyUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :third_party_users do |t|

      t.integer :third_party_type, comment: "第三方平台类型: 1: shopline, 2: aliexpress"
      t.string :third_party_id
      t.string :email
      t.belongs_to :store
      t.string :first_name
      t.string :last_name
      t.string :nick_name
      t.string :gender
      t.string :phone
      t.string :total_spent
      t.integer :orders_count
      t.text :note
      t.integer :state, comment: "0: 已禁用账户, 1: 待启用账户, 2: 已邀请账户, 3: 有效账户"

      t.timestamps
    end
  end
end
