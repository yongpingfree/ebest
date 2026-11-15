# frozen_string_literal: true

class AddParentWebCategoryToAgeVerifications < ActiveRecord::Migration[5.2]
  def change
    add_reference :age_verifications, :parent_web_category, foreign_key: { to_table: :web_categories }
  end
end
