# frozen_string_literal: true

namespace :shopline do
  # desc "initial web category"
  # task initial_category: :environment do |t, args|
  #   MagicBean::Category.show.where.not(parent_id: nil).each do |category|
  #     category.shopline_create_category unless category.shopline_synced?
  #   end
  # end

  desc "initial items"
  task initial_items: :environment do |t, args|
    MagicBean::Item.online.shopline_channel.includes(:on_sale_skus, :shopline_item).each do |item|
      item.shopline_create_item unless item.shopline_synced?
    end
  end

  desc "initial sku inventory locations"
  task initial_items: :environment do |t, args|
    fail_third_party_ids = []
    MagicBean::ThirdPartySku.includes(stock_keeping_unit: :store).shopline.find_each do |sku|
      errors_count = Shopline::Api.connect_inventory(sku.third_party_inventory_item_id, sku.stock_keeping_unit.peti_store?)
      fail_third_party_ids << sku.id if errors_count.positive?
    end

    puts "Connect inventory fail, third_party_ids: #{fail_third_party_ids.join(', ')}"
  end

  desc "Update all skus inventory"
  task update_skus_inventory: :environment do |t, args|
    fail_third_party_ids = []
    MagicBean::ThirdPartySku.includes(stock_keeping_unit: [:item, :store]).shopline.find_each do |t_sku|
      sku = t_sku.stock_keeping_unit
      errors_count = Shopline::Api.update_stock(t_sku.third_party_inventory_item_id, sku.quantity, sku.peti_store?, sku.delivery_type)
      fail_third_party_ids << t_sku.id if errors_count.positive?
    end
    
    puts "Update inventory fail, third_party_ids: #{fail_third_party_ids.join(', ')}"
  end

  desc "Update all item metafields"
  task update_items_metafields: :environment do |t, args|
    fail_third_party_ids = []
    MagicBean::ThirdPartyItem.includes(:item).shopline.find_each do |t_item|
      res = Shopline::Api.set_product_metafields(t_item.item, t_item.third_party_id)
      fail_third_party_ids << t_item.id if res["errors"].present?
    end
    puts "Update item metafields fail, third_party_ids: #{fail_third_party_ids.join(', ')}"
  end
end
