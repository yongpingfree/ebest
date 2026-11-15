# frozen_string_literal: true

class RemoveSearchHotWordsFromSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    remove_column :site_configs, :search_hot_words, :string, array: true, default: []
  end
end
