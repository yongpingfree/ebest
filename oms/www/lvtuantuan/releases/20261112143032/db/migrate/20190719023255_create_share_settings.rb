# frozen_string_literal: true

class CreateShareSettings < ActiveRecord::Migration[5.2]
  def change
    create_table "share_settings" do |t|
      t.string "share_background_cover"
      t.string "share_words"
      t.string "share_cover"
      t.string "target_type"
      t.bigint "target_id"

      t.timestamps

      t.index ["target_type", "target_id"], name: "index_share_settings_on_target_type_and_target_id"
    end
  end
end
