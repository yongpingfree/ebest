class AddExternalUrlToCategories < ActiveRecord::Migration[5.2]
  def change
    add_column :categories, :external_url, :string
  end
end
