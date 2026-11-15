# frozen_string_literal: true

class CreateAeCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :ae_categories do |t|
      t.string :name, null: false
      t.string :ae_id, null: false, index: true
      t.jsonb :product_required_attributes
      t.jsonb :sku_attributes
      t.timestamps
    end

    say_with_time "Initial categories" do
      MagicBean::AeCategory.reset_column_information
      data = File.read(Rails.root.join("db/data/category.jsonl"))
      categories = JSON.parse(data)["categories"]
      categories.each do |cate|
        MagicBean::AeCategory.create!(name: cate["name"], ae_id: cate["id"])
      end
    end
  end
end
