# frozen_string_literal: true

class SetDefaultFixedFreightToItems < ActiveRecord::Migration[5.2]
  def change
    change_column_default :items, :fixed_freight, from: nil, to: 0
  end
end
