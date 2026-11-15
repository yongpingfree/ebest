# frozen_string_literal: true

class RenameProductsTitleEn < ActiveRecord::Migration[5.2]
  def change
    rename_column :products, :title_en, :sub_title
  end
end
