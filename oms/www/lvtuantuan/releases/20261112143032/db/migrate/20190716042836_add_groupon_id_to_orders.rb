# frozen_string_literal: true

class AddGrouponIdToOrders < ActiveRecord::Migration[5.2]
  def change
    add_belongs_to :orders, :groupon, foreign_key: true
  end
end
