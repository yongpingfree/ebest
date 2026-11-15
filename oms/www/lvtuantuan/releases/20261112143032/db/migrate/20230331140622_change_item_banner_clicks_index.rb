class ChangeItemBannerClicksIndex < ActiveRecord::Migration[5.2]
  def change
    remove_index :item_banner_clicks, :date
    add_index :item_banner_clicks, [:item_banner_id, :date], unique: true
  end
end
