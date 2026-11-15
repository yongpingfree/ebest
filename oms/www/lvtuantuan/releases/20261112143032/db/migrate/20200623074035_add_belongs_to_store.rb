# frozen_string_literal: true

class AddBelongsToStore < ActiveRecord::Migration[5.2]
  def change
    rename_column :items, :sale_count, :sales_count
    add_belongs_to :site_configs, :store
    add_belongs_to :share_settings, :store
    add_belongs_to :au_suburbs, :store
    add_belongs_to :items, :store
    add_belongs_to :stock_keeping_units, :store
    add_belongs_to :orders, :store
    add_belongs_to :order_items, :store
    add_belongs_to :after_sales, :store
    add_belongs_to :coupon_packages, :store
    add_belongs_to :coupon_templates, :store
    add_belongs_to :coupons, :store
    add_belongs_to :freight_templates, :store
    add_belongs_to :gift_activities, :store
    add_belongs_to :groupon_activities, :store
    add_belongs_to :groupons, :store
    add_belongs_to :self_pick_ups, :store
    add_belongs_to :shopping_cart_items, :store
    add_belongs_to :custom_lists, :store
    add_belongs_to :custom_list_items, :store
    add_belongs_to :custom_pages, :store
    add_belongs_to :operation_records, :store
    add_belongs_to :page_popups, :store
    add_belongs_to :items, :product
    add_belongs_to :products, :qa_and_guarantee
    remove_index :custom_pages, :en_name

    add_column :stores, :short_name, :string
    add_index :stores, :short_name, unique: true

    say_with_time "update store_id" do
      MagicBean::SiteConfig.reset_column_information
      default_store = MagicBean::Store.default.first || MagicBean::Store.create(name: "Sydney", is_default: true)
      MagicBean::Item.update_all(store_id: default_store.id)
      MagicBean::StockKeepingUnit.update_all(store_id: default_store.id)
      MagicBean::Order.update_all(store_id: default_store.id)
      MagicBean::OrderItem.update_all(store_id: default_store.id)
      MagicBean::AfterSale.update_all(store_id: default_store.id)
      MagicBean::FreightTemplate.update_all(store_id: default_store.id)
      MagicBean::GiftActivity.update_all(store_id: default_store.id)
      MagicBean::GrouponActivity.update_all(store_id: default_store.id)
      MagicBean::Groupon.update_all(store_id: default_store.id)
      MagicBean::SelfPickUp.update_all(store_id: default_store.id)
      MagicBean::ShoppingCartItem.update_all(store_id: default_store.id)
      MagicBean::CustomList.update_all(store_id: default_store.id)
      MagicBean::CustomListItem.update_all(store_id: default_store.id)
      MagicBean::CustomPage.update_all(store_id: default_store.id)
      MagicBean::OperationRecord.update_all(store_id: default_store.id)
      MagicBean::PagePopup.update_all(store_id: default_store.id)
      MagicBean::Item.all.each do |item|
        product = MagicBean::Product.create(
          title: item.title,
          title_en: item.sub_title,
          description: item.description,
          shared_description: item.shared_description,
          cover: item.cover,
          share_cover: item.share_cover,
          main_images: item.main_images,
          detail_video: item.detail_video,
          detail_images: item.detail_images,
          actual_monthly_sales_count: item.actual_monthly_sales_count,
          category_id: item.category_id,
          brand_id: item.brand_id,
          store_id: item.store_id,
          qa_and_guarantee_id: item.qa_and_guarantee_id
        )
        item.update(product: product)
      end
    end
  end
end
