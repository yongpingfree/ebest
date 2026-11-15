# frozen_string_literal: true

class AddQaGuaranteeToItems < ActiveRecord::Migration[5.2]
  def change
    add_reference :items, :qa_and_guarantee, foreign_key: true
  end
end
