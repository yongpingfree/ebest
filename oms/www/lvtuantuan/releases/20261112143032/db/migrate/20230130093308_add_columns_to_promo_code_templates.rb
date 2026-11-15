# frozen_string_literal: true

class AddColumnsToPromoCodeTemplates < ActiveRecord::Migration[5.2]
  def change
    add_column :promo_code_templates, :user_kind, :integer, default: 1, comment: "用户类型，1为全部用户，2为新用户"
    add_column :promo_code_templates, :use_times_kind, :integer, default: 1, comment: "使用次数类型，1为不限，2为每人限用1次"
  end
end
