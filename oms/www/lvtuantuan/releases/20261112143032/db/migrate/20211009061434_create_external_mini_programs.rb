# frozen_string_literal: true

class CreateExternalMiniPrograms < ActiveRecord::Migration[5.2]
  def change
    create_table :external_mini_programs do |t|
      t.string :name, null: false
      t.string :origin_id, null: false
      t.string :path, null: false
      t.string :app_id, null: false
      t.integer :env_version, null: false, default: 0, comment: "小程序版本：0 release 正式版, 1 develop 开发版, 2 trial 体验版"

      t.timestamps
    end
  end
end
