# frozen_string_literal: true

class AddSearchKeywordsToCategories < ActiveRecord::Migration[5.2]
  def change
    add_column :categories, :search_keywords, :text, comment: "搜索关键词, 用于提升搜索商品准确度"
    add_column :web_categories, :search_keywords, :text, comment: "搜索关键词, 用于提升搜索商品准确度"
  end
end
