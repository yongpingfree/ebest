# frozen_string_literal: true

class CreateCustomPages < ActiveRecord::Migration[5.2]
  def change
    create_table :custom_pages do |t|
      t.string "name"
      t.string "en_name"
      t.string "qrcode_url"
      t.json "components"
      t.boolean "default", default: false

      t.index ["en_name"], name: "index_custom_pages_on_en_name", unique: true

      t.timestamps
    end
  end
end
