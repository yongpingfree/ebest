# frozen_string_literal: true

class AddNeedAgeVerificationToCategories < ActiveRecord::Migration[5.2]
  def change
    add_column :categories, :need_age_verification, :boolean, default: false
  end
end
