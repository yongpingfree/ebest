# frozen_string_literal: true

class AddGoBackToEbestIconSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :go_back_to_ebest_right_icon_settings, :jsonb, default: {}, comment: "回到自营页右侧图标设置"
    add_column :site_configs, :go_back_to_ebest_top_left_icon_settings, :jsonb, default: {}, comment: "回到自营页左上角图标设置"
    add_column :site_configs, :go_back_to_ebest_category_icon_settings, :jsonb, default: {}, comment: "回到自营页分类图标设置"
    add_column :site_configs, :go_back_to_ebest_bottom_icon_settings, :jsonb, default: {}, comment: "回到自营页底部图标设置"
  end
end
