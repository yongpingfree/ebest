# frozen_string_literal: true

class AddAeFreightInfoToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :ae_freight_info, :jsonb, comment: "AE物流信息"
  end
end
