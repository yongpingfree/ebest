# frozen_string_literal: true

class AddIsSeasonalToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :is_seasonal, :boolean,default:false
  end
end
