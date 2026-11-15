# frozen_string_literal: true

class AddAeH5DescriptionToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :ae_h5_description, :text
  end
end
