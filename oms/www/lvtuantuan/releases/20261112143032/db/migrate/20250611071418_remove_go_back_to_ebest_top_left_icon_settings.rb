# frozen_string_literal: true

class RemoveGoBackToEbestTopLeftIconSettings < ActiveRecord::Migration[5.2]
  def change
    remove_column :site_configs, :go_back_to_ebest_top_left_icon_settings, :jsonb
  end
end
