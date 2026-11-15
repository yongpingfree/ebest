# frozen_string_literal: true

class AddAeUnsaleableToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :ae_unsaleable, :boolean, default: false, comment: "AE端是否不可销售"
  end
end
