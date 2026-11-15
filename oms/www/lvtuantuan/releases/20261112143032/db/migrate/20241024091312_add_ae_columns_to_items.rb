# frozen_string_literal: true

class AddAeColumnsToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :is_ae_choice, :boolean, comment: "是否是AE官方产品"
    add_column :items, :ae_delivery_date_desc, :string, comment: "AE发货时间描述, 例: Oct. 31 - Nov. 07"
    add_column :items, :ae_delivery_date, :string, comment: "AE发货日期，AE产品的发货日期由AE计算"
    add_column :items, :ae_estimated_delivery_days, :integer, comment: "AE预估发货天数"
  end
end
