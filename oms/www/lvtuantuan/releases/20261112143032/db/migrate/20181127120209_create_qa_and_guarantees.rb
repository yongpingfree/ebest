# frozen_string_literal: true

class CreateQaAndGuarantees < ActiveRecord::Migration[5.2]
  def change
    create_table :qa_and_guarantees do |t|
      t.string :title, null: false
      t.string :image, null: false

      t.timestamps
    end
  end
end
