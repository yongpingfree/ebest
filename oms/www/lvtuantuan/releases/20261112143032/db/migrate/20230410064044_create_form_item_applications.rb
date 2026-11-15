# frozen_string_literal: true

class CreateFormItemApplications < ActiveRecord::Migration[5.2]
  def change
    create_table :form_item_applications do |t|

      t.belongs_to :form_item
      t.belongs_to :user
      t.belongs_to :store
      t.integer :channel
      t.hstore :apply_properties, comment: "申请信息"

      t.timestamps
    end
  end
end
