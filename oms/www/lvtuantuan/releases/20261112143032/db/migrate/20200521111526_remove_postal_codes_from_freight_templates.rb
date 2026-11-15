# frozen_string_literal: true
class RemovePostalCodesFromFreightTemplates < ActiveRecord::Migration[5.2]
  def change
    remove_column :freight_templates, :postal_codes, :string, default: [], array: true
  end
end
