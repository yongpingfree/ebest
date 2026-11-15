# frozen_string_literal: true

class CreateSameDayDeliveryCarts < ActiveRecord::Migration[5.2]
  def change
    create_table :same_day_delivery_carts do |t|

      t.belongs_to :user
      t.timestamps
    end
  end
end
