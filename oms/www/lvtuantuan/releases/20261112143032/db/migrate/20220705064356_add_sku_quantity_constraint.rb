# frozen_string_literal: true

class AddSkuQuantityConstraint < ActiveRecord::Migration[5.2]
  def up
    execute "ALTER TABLE stock_keeping_units ADD CONSTRAINT valid_quantity CHECK (quantity >= 0)"
  end

  def down
    execute "ALTER TABLE stock_keeping_units DROP CONSTRAINT valid_quantity"
  end
end
