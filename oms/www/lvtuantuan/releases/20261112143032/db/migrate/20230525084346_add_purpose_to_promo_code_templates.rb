# frozen_string_literal: true

class AddPurposeToPromoCodeTemplates < ActiveRecord::Migration[5.2]
  def change
    add_column :promo_code_templates, :purpose, :integer, default: 1, comment: "用途"
  end
end
