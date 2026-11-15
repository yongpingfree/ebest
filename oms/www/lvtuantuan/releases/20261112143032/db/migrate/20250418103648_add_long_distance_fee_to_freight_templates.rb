# frozen_string_literal: true

class AddLongDistanceFeeToFreightTemplates < ActiveRecord::Migration[5.2]
  def change
    add_column :freight_templates, :long_distance_fee_in_cent, :integer, default: 0, comment: "远程运费"
  end
end
