# frozen_string_literal: true

class AddHintToMultiLangConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :multi_lang_configs, :hint, :string
  end
end
