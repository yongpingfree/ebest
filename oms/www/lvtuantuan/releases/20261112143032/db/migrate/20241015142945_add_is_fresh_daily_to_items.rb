# frozen_string_literal: true

class AddIsFreshDailyToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :is_fresh_daily, :boolean,default:false
  end
end
