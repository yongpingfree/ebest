# frozen_string_literal: true

namespace :aliexpress do
  desc "initial ae category attributes"
  task initial_category_attributes: :environment do |t, args|
    MagicBean::AeCategory.find_each do |category|
      response = Aliexpress::Api.get_category_attributes category.ae_id
      product_required_attr = response.body["result"]["attributes"].select {|attr| attr["required"] && !attr["sku"] }
      sku_attr = response.body["result"]["attributes"].select {|attr| attr["sku"] }
      category.update_columns product_required_attributes: product_required_attr, sku_attributes: sku_attr
    end
  end

  desc "Export ae category attributes"
  task export_category_attributes: :environment do |t, args|
    output_file = Rails.root.join("tmp", "ae_category.csv")

    File.open(output_file, "w") do |f|
      csv_string = CSV.generate(encoding: "UTF-8") do |csv|
        csv << %w(分类名 分类ID 必填规格名 必填规格选项)

        MagicBean::AeCategory.find_each do |category|
          category.product_required_attributes.each do |attr|
            csv << [category.name, category.ae_id, "#{attr["names"]["zh"]} -- #{attr["id"]}", attr["values"].map {|v| "#{v["names"]["zh"]} -- #{v["id"]}" }]
          end
        end
      end
      csv_string_with_utf8_bom = "\uFEFF" + csv_string

      f.write(csv_string_with_utf8_bom)
    end
  end

  desc "Import item ae attributes"
  task initial_item_attributes: :environment do |t, args|
    file_url = Rails.root.join("tmp/import_ae_products.xlsx")
    xlsx = Roo::Spreadsheet.open(file_url, extension: :xlsx)

    result = xlsx.sheet(0).parse(headers: true)
    headers = result.first.keys
    product_attribute_keys = headers.select {|key| key.include?("attribute") }
    freight_keys = headers.select {|key| key.include?("freight_") }

    # 跳过前两行
    error_messages = []
    sydney_store = MagicBean::Store.sydney

    result[2..-1].each_with_index do |res, i|
      item_errors = []
      freight_info = {}
      ae_product_attributes = []

      item = MagicBean::Item.find_by(store_id: sydney_store.id, no: res["item_no"].to_s.strip)
      sku = item&.stock_keeping_units&.find_by no: res["sku_no"].to_s.strip
      item_errors << "第#{i + 3}行：悉尼门店找不到商品或SKU" if item.blank? || sku.blank?

      if freight_keys.any? {|key| res[key].blank? }
        item_errors << "第#{i + 3}行：物流重量/长宽高均必填"
      else
        freight_keys.each do |key|
          freight_info[key.to_sym] = res[key].to_s.strip
        end
      end

      if product_attribute_keys.all? {|key| res[key].blank? }
        item_errors << "第#{i + 3}行：产品属性必填字段不能全为空"
      else
        product_attribute_keys.each do |key|
          # 如果必填值为空，则跳过
          value = res[key].to_s.strip
          next if value.blank?
          # 要拿第二行的title作为ID
          ae_product_attributes << { id: result[1][key].to_s.strip, value: value }
        end
      end

      if item_errors.present?
        error_messages << item_errors.join(", ")
        next
      end

      item.ae_freight_info = freight_info
      item.ae_product_attributes = ae_product_attributes
      item.ae_category_id = res["ae_category_id"].to_s.strip if res["ae_category_id"].present?
      item.channels += ["aliexpress"]  unless item.channel_match?("aliexpress")

      item.save(validate: false)
    end

    puts error_messages.join("; ")
  end

  desc "create items"
  task create_items: :environment do |t, args|
    error_messages = []
    synced_ids = MagicBean::ThirdPartyItem.where(third_party_type: "aliexpress").map(&:item_id)
    MagicBean::Item.online.aliexpress_channel.where.not(ae_product_attributes: nil, id: synced_ids).includes(:on_sale_skus, :ae_item, :translations).each do |item|
      next if item.aliexpress_synced?
      response = item.aliexpress_create_item
      error_messages << {
        no: item.no,
        sku: item.on_sale_skus.first.no,
        error: response.body
      } if response&.body.dig("error_response")
    end

    # 将错误信息导出excel
    output_file = Rails.root.join("tmp", "create_ae_item_errors.csv")

    File.open(output_file, "w") do |f|
      csv_string = CSV.generate(encoding: "UTF-8") do |csv|
        csv << %w(item_no sku_no error)

        error_messages.each do |message|
          csv << [message[:no], message[:sku], message[:error]["error_response"]["sub_msg"] || message[:error]["error_response"]["msg"]]
        end
      end
      csv_string_with_utf8_bom = "\uFEFF" + csv_string

      f.write(csv_string_with_utf8_bom)
    end

    puts error_messages
  end

  desc "update items"
  task update_items: :environment do |t, args|
    error_messages = []
    MagicBean::Item.online.aliexpress_channel.where(id: MagicBean::ThirdPartyItem.aliexpress.select(:item_id)).includes(:on_sale_skus, :ae_item, :translations).each do |item|
      next unless item.aliexpress_synced?
      response = item.aliexpress_update_item
      error_messages << {
        no: item.no,
        sku: item.on_sale_skus.first.no,
        error: response.body
      } if response&.body.dig("error_response")
    end

    puts error_messages
  end

  desc "sync items"
  task sync_items: :environment do |t, args|
    sydney_store = MagicBean::Store.sydney
    return if sydney_store.blank?

    ["onSelling", "auditing", "editingRequired", "offline"].each do |product_status_type|
      current_page = 1
      while true
        response = Aliexpress::Product.list(product_status_type, current_page: current_page)
        result = response.body.dig("result")
        break if result.blank?

        total_page = result["total_page"]
        break if total_page.zero?

        product_count = result["product_count"]

        puts "product_status_type: #{product_status_type}, current_page: #{current_page}, total_page: #{total_page}, product_count: #{product_count}"

        deal_products(result["aeop_a_e_product_display_d_t_o_list"], sydney_store.id)

        break if current_page >= total_page
        current_page += 1
      end
    end
  end

  def deal_products(products, stock_id)
    puts "products size #{products&.size.to_i}"
    return if products.blank?
    products.each do |product|
      product_id = product["product_id"]
      product_resp = Aliexpress::Product.show(product_id)
      puts "Product #{product_id} start sync..."

      product_result = product_resp.body.dig("result")
      next if product_result.blank?

      sku_resp = product_result["aeop_ae_product_s_k_us"].first
      next if sku_resp.dig("sku_code").blank?

      puts "SKU: #{sku_resp["sku_code"]} start sync..."

      sku = MagicBean::StockKeepingUnit.find_by(no: sku_resp["sku_code"], store_id: stock_id)
      next if sku.blank?
      puts "SKU: #{sku.no} synced?: #{sku.ae_sku.present?}"

      if sku.ae_sku.nil?
        build_result = sku.build_ae_sku(third_party_id: sku_resp["sku_Id"]).save
        puts "SKU: #{sku.no} build result: #{build_result}"
      end

      item = sku.item
      if item.ae_item.nil?
        build_result = item.build_ae_item(third_party_id: product_id).save
        puts "Item: #{item.no} build result: #{build_result}"
      end

      puts "SKU: #{sku_resp["sku_code"]} sync end..."
    end
  end

  desc "Sync skus stock from xls"
  task sync_skus_stock_from_xls: :environment do |t, args|
    file_url = Rails.root.join("tmp/import_skus_stock.xlsx")
    xlsx = Roo::Spreadsheet.open(file_url, extension: :xlsx)
    result = xlsx.sheet(0).parse(headers: true)

    not_found_skus = []
    not_synced_skus = []

    messages = []
    error_messages = []
    result[2..-1].each_with_index do |row, i|
      no = row["sku_no"].to_s.strip
      stock = row["stock"].to_i
      sku = MagicBean::StockKeepingUnit.find_by no: no
      if sku.blank?
        not_found_skus << no
        next
      end

      unless sku.aliexpress_synced?
        not_synced_skus << no
        next
      end

      begin
        response = MagicBean::StockKeepingUnit.aliexpress_sync_stock(sku, stock)
        messages << "第#{i + 3}行, no: #{no}, stock: #{stock}, response: #{response}"
      rescue => e
        error_messages << "第#{i + 3}行, no: #{no}, stock: #{stock}, error: #{e.message}"
      end
    end
    puts "messages: #{messages.join("; ")}" if messages.present?
    puts "error_messages: #{error_messages.join("; ")}" if error_messages.present?

    puts "not_found_skus: #{not_found_skus.join("; ")}" if not_found_skus.present?
    puts "not_synced_skus: #{not_synced_skus.join("; ")}" if not_synced_skus.present?
  end

  desc "Sync skus price from xls"
  task sync_skus_price_from_xls: :environment do |t, args|
    file_url = Rails.root.join("tmp/import_skus_price.xlsx")
    xlsx = Roo::Spreadsheet.open(file_url, extension: :xlsx)
    result = xlsx.sheet(0).parse(headers: true)

    not_found_skus = []
    not_synced_skus = []
    price_blank_skus = []

    messages = []
    error_messages = []
    result[2..-1].each_with_index do |row, i|
      no = row["sku_no"].to_s.strip
      price_in_yuan = row["price"].to_i
      if price_in_yuan.blank?
        price_blank_skus << no
        next
      end

      sku = MagicBean::StockKeepingUnit.find_by no: no
      if sku.blank?
        not_found_skus << no
        next
      end

      unless sku.aliexpress_synced?
        not_synced_skus << no
        next
      end

      begin
        ae_price_in_cent = (price_in_yuan.to_f * 100).round
        sku.update_columns(ae_price_in_cent: ae_price_in_cent)
        response = MagicBean::StockKeepingUnit.aliexpress_sync_price(sku, price_in_yuan)
        messages << "第#{i + 3}行, no: #{no}, price_in_yuan: #{price_in_yuan}, response: #{response}"
      rescue => e
        error_messages << "第#{i + 3}行, no: #{no}, price_in_yuan: #{price_in_yuan}, error: #{e.message}"
      end
    end
    puts "messages: #{messages.join("; ")}" if messages.present?
    puts "error_messages: #{error_messages.join("; ")}" if error_messages.present?

    puts "price_blank_skus: #{price_blank_skus.join("; ")}" if price_blank_skus.present?
    puts "not_found_skus: #{not_found_skus.join("; ")}" if not_found_skus.present?
    puts "not_synced_skus: #{not_synced_skus.join("; ")}" if not_synced_skus.present?
  end

  desc "Sync skus id from ae"
  task  sync_skus_id_from_ae: :environment do |t, args|
    not_found_items = []
    MagicBean::Item.online.aliexpress_channel.where(id: MagicBean::ThirdPartyItem.aliexpress.select(:item_id)).includes(:on_sale_skus, :ae_item).each do |item|
      ae_sku = item.on_sale_skus.first&.ae_sku
      next if ae_sku.present? && ae_sku.third_party_inventory_item_id.present?

      product_resp = Aliexpress::Product.show(item.ae_item.third_party_id)
      product_result = product_resp&.body.dig("result")
      if product_result.present?
        sku_resp = product_result["aeop_ae_product_s_k_us"].first

        if sku_resp.dig("id").present?
          sku = item.on_sale_skus.select { |sku| sku.no == sku_resp["sku_code"] }.first
          sku.build_ae_sku(
            third_party_id: sku_resp["id"],
            third_party_inventory_item_id: sku_resp["sku_Id"]
          ).save
        end
      else
        not_found_items << item.id
      end
    end
    puts "not_found_items: #{not_found_items}"
  end

  desc "初始化dropshipper分类到 categories 表"
  task initialize_dropshipper_parent_categories: :environment do
    categories = [
      { category_name: "Food", category_id: "2" },
      { category_name: "Apparel & Accessories", category_id: "3" },
      { category_name: "Home Appliances", category_id: "6" },
      { category_name: "Computer & Office", category_id: "7" },
      { category_name: "Home Improvement", category_id: "13" },
      { category_name: "Home & Garden", category_id: "15" },
      { category_name: "Sports & Entertainment", category_id: "18" },
      { category_name: "Office & School Supplies", category_id: "21" },
      { category_name: "Toys & Hobbies", category_id: "26" },
      { category_name: "Security & Protection", category_id: "30" },
      { category_name: "Automobiles, Parts & Accessories", category_id: "34" },
      { category_name: "Jewelry & Accessories", category_id: "36" },
      { category_name: "Lights & Lighting", category_id: "39" },
      { category_name: "Consumer Electronics", category_id: "44" },
      { category_name: "Beauty & Health", category_id: "66" },
      { category_name: "Weddings & Events", category_id: "320" },
      { category_name: "Shoes", category_id: "322" },
      { category_name: "Electronic Components & Supplies", category_id: "502" },
      { category_name: "Phones & Telecommunications", category_id: "509" },
      { category_name: "Test category 06", category_id: "127698009" },
      { category_name: "Tools", category_id: "1420" },
      { category_name: "Mother & Kids", category_id: "1501" },
      { category_name: "Furniture", category_id: "1503" },
      { category_name: "Watches", category_id: "1511" },
      { category_name: "Luggage & Bags", category_id: "1524" },
      { category_name: "Women's Clothing", category_id: "200000345" },
      { category_name: "Men's Clothing", category_id: "200000343" },
      { category_name: "Apparel Accessories", category_id: "200000297" },
      { category_name: "Hair Extensions & Wigs", category_id: "200165144" },
      { category_name: "Special Category", category_id: "200001075" },
      { category_name: "Underwear", category_id: "200574005" },
      { category_name: "Novelty & Special Use", category_id: "200000532" },
      { category_name: "Virtual Products", category_id: "201169612" },
      { category_name: "Sports Shoes,Clothing&Accessories", category_id: "201768104" },
      { category_name: "Second-Hand", category_id: "201520802" },
      { category_name: "Motorcycle Equipments & Parts", category_id: "201355758" }
    ]
    categories.each do |category|
      next if category[:category_name].blank?
      new_category =  MagicBean::Category.find_or_initialize_by(ae_drop_shipper_category_id: category[:category_id])
      new_category.ae_drop_shipper = true
      new_category.name_zh_cn = EasyTranslate.translate(category[:category_name], from: :en, to: :"zh-CN")
      new_category.name_en = category[:category_name]
      new_category.status = "show"
      new_category.save!
    end
  end

  desc "初始化dropshipper商品到 items 表"
  task initialize_dropshipper_items: :environment do
    MagicBean::Category.where(ae_drop_shipper: true).top.each do |category|
      puts "category: #{category.ae_drop_shipper_category_id}"
      get_product_ids_by_search_id(category.ae_drop_shipper_category_id)
      puts "---- done ----"
    end
  end

  desc "更新AE Choice商品到 items 表"
  task update_ae_items_choice: :environment do
    MagicBean::Item.where(ae_drop_shipper: true, is_ae_choice: nil).not_deleted.find_each do |item|
      retry_times = 2
      
      begin
        detail_response = Aliexpress::Api.get_dropshipper_product_detail(item.no)

        rsp_code = detail_response.body.dig("rsp_code")
        
        # 商品下架或不存在时，返回604或605
        # 482: 商品禁止在该区域销售
        if rsp_code.in?(MagicBean::Item::AE_UNSALEABLE_CODE)
          # 将商品下架
          item.ae_unsaleable_offline!
          next
        end

        product_result = detail_response.body.dig("result")
        item_properties = product_result["ae_item_properties"]
        is_ae_choice = item_properties.any? {|property| property["attr_name_id"] == -1 && property["attr_name"] == "Choice" && property["attr_value"] == "yes" }
        item.update_columns(is_ae_choice: is_ae_choice)
      rescue => e
        puts "item: #{item.id}, error: #{e.message}"
        # 请求可能会超过频率导致失败，需要重试
        retry_times -= 1
        retry_times > 0 ? retry : false
      end
    end
  end

  desc "更新AE Choice商品的预计发货时间"
  task update_ae_items_delivery_date: :environment do
    # 官方商品都用CAINIAO_FULFILLMENT_STD配送，非官方有多种配送方式，先不处理
    MagicBean::Item.where(ae_drop_shipper: true, is_ae_choice: true).not_deleted.includes(:stock_keeping_units).find_each do |item|
      item.update_ae_choice_delivery_date
    end
  end

  desc "更新AE商品的售价"
  task update_ae_skus_price: :environment do
    # 现在保存的价格是原价，需要乘以进货价倍数
    sydney_store = MagicBean::Store.sydney
    ae_sku_cost_minimum_factor = sydney_store.site_config&.ae_sku_cost_minimum_factor
    return if ae_sku_cost_minimum_factor.blank?
    MagicBean::StockKeepingUnit.ransack(item_ae_drop_shipper_eq: true).result.update_all("price_in_cent = ROUND(CAST(price_in_cent * #{ae_sku_cost_minimum_factor} AS numeric), 0)")
  end

  desc "清除AE unsaleable的商品"
  task clear_ae_drop_shipper_unsaleable_items: :environment do
    MagicBean::Item.where(ae_drop_shipper: true, ae_unsaleable: true).not_deleted.find_each do |item|
      item.destroy if item.destroyable?
    end
  end

  private
  def get_product_ids_by_search_id(category_id, search_id = "")
    response = Aliexpress::Api.get_dropshipper_product_ids(category_id, search_id)
    product_ids = response.body.dig("result", "products") || []
    return if product_ids.blank?

    error_product_ids = []
    product_ids.each do |product_id|
      error_product_ids << product_id unless MagicBean::Item.create_ae_item(product_id)
    end
    puts "error_product_ids: #{error_product_ids.join(", ")}"
    search_id = response.body.dig("result", "search_id")
    get_product_ids_by_search_id(category_id, search_id) if search_id.present?
  end
end
