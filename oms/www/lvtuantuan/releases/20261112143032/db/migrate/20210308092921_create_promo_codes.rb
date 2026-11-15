# frozen_string_literal: true

class CreatePromoCodes < ActiveRecord::Migration[5.2]
  def change
    create_table :promo_codes do |t|
      t.string :code
      t.belongs_to :order
      t.belongs_to :promo_code_template

      t.timestamps
    end

    add_index :promo_codes, [:promo_code_template_id, :code], unique: true
  end
end
