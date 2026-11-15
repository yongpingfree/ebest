# frozen_string_literal: true

class AddUnionidAndOfficialOpenIdToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :unionid, :string
    add_column :users, :official_open_id, :string, comment: "公众号 oepnid"
    add_column :users, :subscribe, :boolean

    add_index :users, :unionid, unique: true
  end
end
