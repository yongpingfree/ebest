# frozen_string_literal: true

class AddAeBasicInfoLastUpdatedDate < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :ae_basic_info_last_updated_date, :date, comment: "AE商品基础信息最后更新日期"
  end
end
