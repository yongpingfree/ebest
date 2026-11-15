# frozen_string_literal: true

class AddNewAttrsToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :production_place, :string, comment: "产地"
    add_column :items, :allergen, :string, comment: "过敏原"
    add_column :items, :serving_per_package, :string, comment: "本包装包含份数"
    add_column :items, :serving_size, :string, comment: "每一份的份量"
  end
end
