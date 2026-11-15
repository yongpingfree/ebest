# frozen_string_literal: true

class ChangeThirdPartyCategoriesRelations < ActiveRecord::Migration[5.2]
  def change
    remove_belongs_to :third_party_categories, :web_category
    add_belongs_to :third_party_categories, :category
  end
end
