# frozen_string_literal: true

class CreatePromoCodeTemplates < ActiveRecord::Migration[5.2]
  def change
    create_table :promo_code_templates do |t|
      t.belongs_to :store

      t.string :title
      t.boolean :enabled, default: false
      t.date :start_on
      t.date :end_on
      t.string :remark

      t.timestamps
    end
  end
end
