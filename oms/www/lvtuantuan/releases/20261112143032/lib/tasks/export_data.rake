# frozen_string_literal: true

namespace :export_data do
  desc "Export banner clicks to csv (up to yesterday or specified date range)"
  task :export_banner_clicks_to_csv, [:start_date, :end_date] => :environment  do |t, args|
    # Usage:
    #   $ rails export_data:export_banner_clicks_to_csv
    #   $ rails 'export_data:export_banner_clicks_to_csv[2021-07-11,2021-07-12]'

    start_date = args[:start_date].present? ? args[:start_date].to_date : MagicBean::BannerClick.order(:id).first.date
    end_date = args[:end_date].present? ? args[:end_date].to_date : Date.yesterday

    date_format = "%Y%m%d"
    output_filename = Rails.root.join("tmp", "banner-clicks-from-#{start_date.strftime(date_format)}-to-#{end_date.strftime(date_format)}.csv")

    CSV.open(output_filename, "w", write_headers: true, headers: ["date", "url", "count"]) do |csv|
      MagicBean::BannerClick.where(date: start_date..end_date).order(:date).find_each do |banner_click|
        csv << [banner_click.date.strftime(date_format), banner_click.url, banner_click.count]
      end
    end

    puts "Data exported to #{output_filename}"
  end

  desc "Export user and shopping cart items count"
  task export_user_and_shopping_cart_items_count: :environment do
    puts "Exporting"
    CSV.open(Rails.root.join("tmp", "user_shopping_cart_items_count.csv"), "w") do |csv|
      MagicBean::User.find_each do |user|
        csv << [user.id, user.nickname, user&.member&.mobile, user&.shopping_cart&.shopping_cart_items&.count.to_i]
      end
    end
    puts "Done"
  end

  desc "Export duplicated barcode items"
  task export_duplicated_barcode_items: :environment do
    puts "Exporting"

    host = Rails.application.credentials.dig(Rails.env.to_sym, :domain)
    MagicBean::Store.find_each do |store|
      barcode_map = {}

      MagicBean::StockKeepingUnit.where(store_id: store.id).find_each do |sku|
        barcode = sku.barcode.to_s
        barcode_map[barcode] ||= []
        barcode_map[barcode].push(sku.item_id)
      end

      output_file = Rails.root.join("tmp", "duplicated_sku_barcode_of_#{store.name}_#{Time.current.strftime('%Y%m%d')}.csv")
      CSV.open(output_file, "w") do |csv|
        barcode_map.each do |key, item_ids|
          if item_ids.size > 1
            items_url = MagicBean::Item.where(id: item_ids).pluck(:id).map { |item_id| "#{host}/admin/stores/#{store.id}/items/#{item_id}/edit" }
            csv << ([key, items_url].flatten)
          end
        end
      end

      puts "File is saved to #{output_file}"
    end

    puts "Done"
  end

  desc "Export item sales count with maximum"
  task :export_item_sales_count_with_maximum, [:past_days, :max_count] => :environment do |t, args|
    # Usage:
    #   $ rails 'export_data:export_item_sales_count_with_maximum[90,5]'

    past_days = args[:past_days].present? ? args[:past_days].to_i : nil
    max_count = args[:max_count].to_i

    raise ArgumentError.new("passing the wrong number of arguments") if past_days.nil? || max_count.nil?

    start_time = Date.today.days_ago(past_days).beginning_of_day
    paid_order_ids = MagicBean::Order.paid.where("created_at > ?", start_time).pluck(:id)
    sku_sales_count_map = MagicBean::OrderItem.where(order_id: paid_order_ids).group(:stock_keeping_unit_id).sum(:quantity)

    # 1. 找出 0 销量的商品
    zero_sales_skus = MagicBean::StockKeepingUnit.includes(item: [:parent_category]).where.not(id: sku_sales_count_map.keys)

    # 2. 找出销量小于等于指定数的商品
    sku_sales_count_map.each_pair do |sku_id, sales_count|
      sku_sales_count_map.delete(sku_id) if sales_count > max_count
    end
    sku_ids = sku_sales_count_map.keys

    # 3. 写入文件
    output_file = Rails.root.join("tmp", "sku_sales_count_in_last_#{past_days}_days_#{Time.current.strftime('%Y%m%d')}.csv")
    CSV.open(output_file, "w", write_headers: true, headers: ["一级分类", "产品名称", "barcode", "#{past_days}天销量"]) do |csv|
      zero_sales_skus.each do |sku|
        csv << [sku.parent_category_name, sku.human_title, sku.barcode, 0]
      end

      MagicBean::StockKeepingUnit.includes(item: [:parent_category]).where(id: sku_ids).find_each do |sku|
        csv << [sku.parent_category_name, sku.human_title, sku.barcode, sku_sales_count_map[sku.id]]
      end
    end

    puts "Data is saved to #{output_file}"
  end

  desc "Export yearly report"
  task :yearly_report, [:year] => :environment do |t, args|
    # Usage:
    #   $ rails 'export_data:yearly_report[2021]'

    year = args[:year].to_i
    raise ArgumentError.new("passing the wrong number of arguments") if year.nil?

    start_time = Date.new(year, 1, 1).beginning_of_day
    end_time = Date.new(year, 12, 31).end_of_day

    orders = MagicBean::Order.paid.where(created_at: start_time..end_time)
    orders_sum = orders.group(:user_id).sum(:actually_amount_in_cent)
    orders_sum_sorted_user_ids = orders_sum.sort_by { |_key, value| value }.reverse.to_h.keys

    output_file = Rails.root.join("tmp", "yearly_report_#{year}.csv")
    CSV.open(output_file, "w", write_headers: true, headers: ["用户ID", "用户手机号", "消费总额", "消费次数", "排名"]) do |csv|
      orders_sum_sorted_user_ids.each_with_index do |user_id, idx|
        user = MagicBean::User.includes(:member).find user_id
        mobile = user.member.mobile
        total_amount_in_yuan = ActiveSupport::NumberHelper.number_to_currency(orders_sum[user_id] / 100.0, format: "%n", delimiter: "")
        order_count = orders.where(user_id: user_id).count
        csv << [user_id, mobile, total_amount_in_yuan, order_count, idx + 1]
      end
    end

    puts "Data is saved to #{output_file}"
  end

  desc "Export user order data"
  task :user_order_data, [:start_date, :end_date] => :environment do |t, args|
    start_date = args[:start_date]
    end_date = args[:end_date]
    raise ArgumentError.new("passing the wrong number of arguments") if start_date.nil? || end_date.nil?

    start_time = start_date.to_date.beginning_of_day
    end_time = end_date.to_date.end_of_day

    orders = MagicBean::Order.paid.where(created_at: start_time..end_time)
    orders_sum = orders.group(:user_id).sum(:actually_amount_in_cent)
    orders_count = orders.group(:user_id).count

    output_file = Rails.root.join("tmp", "user_order_date_#{start_date}-#{end_date}.csv")

    File.open(output_file, "w") do |f|
      csv_string = CSV.generate(encoding: "UTF-8") do |csv|
        csv << ["用户ID", "用户手机号", "消费总额", "消费次数"]
        MagicBean::User.includes(:member).where(id: orders_sum.keys).each do |user|
          mobile = user.member.mobile
          total_amount_in_yuan = ActiveSupport::NumberHelper.number_to_currency(orders_sum[user.id] / 100.0, format: "%n", delimiter: "")
          order_count = orders_count[user.id]
          csv << [user.id, mobile, total_amount_in_yuan, order_count]
        end
      end
      csv_string_with_utf8_bom = "\uFEFF" + csv_string

      f.write(csv_string_with_utf8_bom)
    end

    puts "Data is saved to #{output_file}"
  end

  desc "Export coupons usage csv"
  task :coupons_usage_csv, [:start_date, :end_date] => :environment do |t, args|
    # Usage:
    #   $ rails 'export_data:coupons_usage_csv[2022-04-01,2022-04-30,2]'

    start_date = args[:start_date]
    end_date = args[:end_date]

    raise ArgumentError.new("passing the wrong number of arguments") if start_date.blank? || end_date.blank?

    start_at = Date.parse(start_date).beginning_of_day
    end_at = Date.parse(end_date).end_of_day
    time_range = start_at..end_at

    coupon_template_ids = MagicBean::Coupon.where(created_at: time_range).pluck(:coupon_template_id).uniq

    output_file = Rails.root.join("tmp", "coupons-#{start_date}-to-#{end_date}.csv")
    headers = %w[优惠券名称 优惠券生成数量（张） 优惠券使用数量（张）]
    CSV.open(output_file, "w", write_headers: true, headers: headers) do |csv|
      MagicBean::CouponTemplate.where(id: coupon_template_ids).find_each do |coupon_template|
        coupons = coupon_template.coupons.where(created_at: time_range)
        csv << [coupon_template.name, coupons.count, coupons.used.count]
      end
    end

    puts "Data is saved to #{output_file}"
  end

  desc "Export gift data csv"
  task :gift_data_csv, [:start_date, :end_date] => :environment do |t, args|
    start_date = args[:start_date]
    end_date = args[:end_date]

    delivery_dates = start_date.to_date..end_date.to_date
    collection = MagicBean::Order.includes(:store).paid.where(delivery_date: delivery_dates).where.not(gifts_properties: nil).order(:delivery_date)

    hash = {}

    collection.each do |order|
      order.gifts_properties.each do |gift|
        hash_key = "#{order.delivery_date}_#{gift["stock_keeping_unit_id"]}"
        hash[hash_key] ||= gift.merge({ delivery_date: order.delivery_date, gift_count: 0 })
        hash[hash_key][:gift_count] += gift["quantity"]
        hash[hash_key][:store_name] = order.store.name
      end
    end

    output_file = Rails.root.join("tmp", "gift-data-#{start_date}-to-#{end_date}.csv")

    File.open(output_file, "w") do |f|
      csv_string = CSV.generate(encoding: "UTF-8") do |csv|
        csv << %w[门店 下单日期 赠品名称 赠品sku 赠品单价 赠品数量]
        hash.values.each do |gift_value|
          csv << [gift_value[:store_name], gift_value[:delivery_date], "#{gift_value["title"]} - #{gift_value["properties_text"]}", gift_value["no"], gift_value["price_in_yuan"], gift_value[:gift_count]]
        end
      end
      csv_string_with_utf8_bom = "\uFEFF" + csv_string

      f.write(csv_string_with_utf8_bom)
    end

    puts "Data is saved to #{output_file}"
  end

  desc "Export gift data csv"
  task :gift_data_csv_by_created_at, [:start_date, :end_date] => :environment do |t, args|
    start_date = args[:start_date]
    end_date = args[:end_date]

    time_range = (start_date.to_date.beginning_of_day)..(end_date.to_date.end_of_day)
    collection = MagicBean::Order.includes(:store).paid.where(created_at: time_range).where.not(gifts_properties: nil).order(:created_at)

    hash = {}

    collection.each do |order|
      order.gifts_properties.each do |gift|
        order_date = order.created_at.to_date
        hash_key = "#{order_date}_#{gift["stock_keeping_unit_id"]}"
        hash[hash_key] ||= gift.merge({ order_date: order_date, gift_count: 0 })
        hash[hash_key][:gift_count] += gift["quantity"]
        hash[hash_key][:store_name] = order.store.name
      end
    end

    output_file = Rails.root.join("tmp", "gift-data-#{start_date}-to-#{end_date}.csv")

    File.open(output_file, "w") do |f|
      csv_string = CSV.generate(encoding: "UTF-8") do |csv|
        csv << %w[门店 下单日期 赠品名称 赠品sku 赠品单价 赠品数量]
        hash.values.each do |gift_value|
          csv << [gift_value[:store_name], gift_value[:order_date], "#{gift_value["title"]} - #{gift_value["properties_text"]}", gift_value["no"], gift_value["price_in_yuan"], gift_value[:gift_count]]
        end
      end
      csv_string_with_utf8_bom = "\uFEFF" + csv_string

      f.write(csv_string_with_utf8_bom)
    end

    puts "Data is saved to #{output_file}"
  end

  desc "导出卧龙岗用户的订单数据（按月）"
  task :wollongong_order_data_csv_by_month, [:start_date, :end_date] => :environment do |t, args|
    start_date = args[:start_date]
    end_date = args[:end_date]

    export_csv_data = {}

    # 先获取所有卧龙岗用户
    MagicBean::User.includes(:member).where(id: MagicBean::Order.merchant_delivery.where(delivery_time_id: [11, 22, 23]).or(MagicBean::Order.self_pick.where(self_pick_up_id: 11)).select(:user_id)).each do |user|
      export_csv_data["#{user.id}"] = { id: user.id, mobile: user.member.mobile, nickname: user.origin_nickname.presence || user.nickname, order_data: {} }
    end

    time_range = (start_date.to_date.beginning_of_day)..(end_date.to_date.end_of_day)

    MagicBean::Order.merchant_delivery.where(delivery_time_id: [11, 22, 23]).or(MagicBean::Order.self_pick.where(self_pick_up_id: 11)).paid.where(created_at: time_range).order(:created_at).each do |order|
      target_order_data_hash = export_csv_data["#{order.user_id}"][:order_data]
      # 以收货电话和订单年月作为唯一key
      order_month = order.created_at.strftime("%Y-%m")
      key = "#{order.receiver_tel_number}:#{order_month}"
      if target_order_data_hash[key].present?
        target_order_data_hash[key][:orders_count] += 1
        target_order_data_hash[key][:original_payment_in_cent] += order.original_payment_in_cent
        target_order_data_hash[key][:actually_amount_in_cent] += order.actually_amount_in_cent
      else
        # 为方便等会遍历, 把收货电话和年月也写到hash
        target_order_data_hash[key] = { receiver_tel_number: order.receiver_tel_number, order_month: order_month, orders_count: 1, original_payment_in_cent: order.original_payment_in_cent, actually_amount_in_cent: order.actually_amount_in_cent }
      end
    end

    output_file = Rails.root.join("tmp", "wollongong-order-month-data-#{start_date}-to-#{end_date}.csv")

    File.open(output_file, "w") do |f|
      csv_string = CSV.generate(encoding: "UTF-8") do |csv|
        csv << %w[用户ID 注册手机号 用户昵称 收货手机号 支付月份 支付月份的订单数 支付月份的支付金额 支付月份的实际支付金额]
        export_csv_data.values.each do |user_data|
          if user_data[:order_data].blank?
            csv << [user_data[:id], user_data[:mobile], user_data[:nickname]]
          else
            user_data[:order_data].values.each do |order_data|
              original_payment_in_yuan = ActiveSupport::NumberHelper.number_to_currency(order_data[:original_payment_in_cent] / 100.0, format: "%n", delimiter: "")
              actually_amount_in_yuan = ActiveSupport::NumberHelper.number_to_currency(order_data[:actually_amount_in_cent] / 100.0, format: "%n", delimiter: "")

              csv << [user_data[:id], user_data[:mobile], user_data[:nickname], order_data[:receiver_tel_number], order_data[:order_month], order_data[:orders_count], original_payment_in_yuan, actually_amount_in_yuan]
            end
          end
        end
      end
      csv_string_with_utf8_bom = "\uFEFF" + csv_string

      f.write(csv_string_with_utf8_bom)
    end

    puts "Data is saved to #{output_file}"
  end

  desc "导出卧龙岗用户的订单数据（按周）"
  task :wollongong_order_data_csv_by_week, [:start_date, :end_date] => :environment do |t, args|
    start_date = args[:start_date]
    end_date = args[:end_date]

    export_csv_data = {}

    # 先获取所有卧龙岗用户
    MagicBean::User.includes(:member).where(id: MagicBean::Order.merchant_delivery.where(delivery_time_id: [11, 22, 23]).or(MagicBean::Order.self_pick.where(self_pick_up_id: 11)).select(:user_id)).each do |user|
      export_csv_data["#{user.id}"] = { id: user.id, mobile: user.member.mobile, nickname: user.origin_nickname.presence || user.nickname, order_data: {} }
    end

    time_range = (start_date.to_date.beginning_of_day)..(end_date.to_date.end_of_day)

    MagicBean::Order.merchant_delivery.where(delivery_time_id: [11, 22, 23]).or(MagicBean::Order.self_pick.where(self_pick_up_id: 11)).paid.where(created_at: time_range).order(:created_at).each do |order|
      target_order_data_hash = export_csv_data["#{order.user_id}"][:order_data]
      # 以收货电话和订单年月作为唯一key
      order_month = order.created_at.strftime("%Y-%m")
      current_day = order.created_at.strftime("%d").to_i

      current_week = if current_day <= 7
                       1
                     elsif current_day <= 14
                       2
                     elsif current_day <= 21
                       3
                     elsif current_day <= 28
                       4
                     else
                       5
                     end

      key = "#{order.receiver_tel_number}:#{order_month}:#{current_week}"
      if target_order_data_hash[key].present?
        target_order_data_hash[key][:orders_count] += 1
        target_order_data_hash[key][:original_payment_in_cent] += order.original_payment_in_cent
        target_order_data_hash[key][:actually_amount_in_cent] += order.actually_amount_in_cent
      else
        # 为方便等会遍历, 把收货电话和年月也写到hash
        target_order_data_hash[key] = { receiver_tel_number: order.receiver_tel_number, order_week: "#{order_month} 第#{current_week}周", orders_count: 1, original_payment_in_cent: order.original_payment_in_cent, actually_amount_in_cent: order.actually_amount_in_cent }
      end
    end

    output_file = Rails.root.join("tmp", "wollongong-order-week-data-#{start_date}-to-#{end_date}.csv")

    File.open(output_file, "w") do |f|
      csv_string = CSV.generate(encoding: "UTF-8") do |csv|
        csv << %w[用户ID 注册手机号 用户昵称 收货手机号 支付月份所在周数 支付月份所在周数的订单数 支付月份所在周数的支付金额 支付月份所在周数的实际支付金额]
        export_csv_data.values.each do |user_data|
          if user_data[:order_data].blank?
            csv << [user_data[:id], user_data[:mobile], user_data[:nickname]]
          else
            user_data[:order_data].values.each do |order_data|
              original_payment_in_yuan = ActiveSupport::NumberHelper.number_to_currency(order_data[:original_payment_in_cent] / 100.0, format: "%n", delimiter: "")
              actually_amount_in_yuan = ActiveSupport::NumberHelper.number_to_currency(order_data[:actually_amount_in_cent] / 100.0, format: "%n", delimiter: "")

              csv << [user_data[:id], user_data[:mobile], user_data[:nickname], order_data[:receiver_tel_number], order_data[:order_week], order_data[:orders_count], original_payment_in_yuan, actually_amount_in_yuan]
            end
          end
        end
      end
      csv_string_with_utf8_bom = "\uFEFF" + csv_string

      f.write(csv_string_with_utf8_bom)
    end

    puts "Data is saved to #{output_file}"
  end

  desc "Export item data with en message csv"
  task item_data_with_en_csv: :environment do |t, args|

    output_file = Rails.root.join("tmp", "export-item-data.csv")

    File.open(output_file, "w") do |f|
      csv_string = CSV.generate(encoding: "UTF-8") do |csv|
        csv << %w[编号 导入编号 中文标题 英文标题 中文描述 英文描述 SKU barcode]

        MagicBean::Item.on_sale.includes(:translations, :stock_keeping_units).order(:created_at).each_slice(200) do |slice_items|
          slice_items.each_with_index do |item, i|
            item.stock_keeping_units.each_with_index do |sku, i|
              item_row = if i.zero?
                           [item.id, "item_no: #{item.no}", item.title_zh_cn, item.title_en, item.description_zh_cn, item.description_en]
                         else
                           [nil, nil, nil, nil, nil, nil]
                         end

              sku_row = item_row + ["no: #{sku.no}", "upc: #{sku.barcode}"]
              csv << sku_row
            end
          end
        end
      end
      csv_string_with_utf8_bom = "\uFEFF" + csv_string

      f.write(csv_string_with_utf8_bom)
    end

    puts "Data is saved to #{output_file}"
  end

  desc "导出悉尼门店配送时间"
  task export_delivery_times: :environment do |t, args|
    output_file = Rails.root.join("tmp", "delivery_times.csv")

    File.open(output_file, "w") do |f|
      csv_string = CSV.generate(encoding: "UTF-8") do |csv|
        csv << %w[配送时间ID 配送时间名称 星期数 配送时间段 Suburb 区号 包邮门槛]
        ids = (2..9).to_a + [11, 13, 16, 19, 21, 22, 23, 24, 25, 37, 38, 40, 43]

        store = MagicBean::Store.find_by name: "Sydney"

        MagicBean::DeliveryTime.includes(:delivery_areas).where(id: ids).each do |time|
          time.delivery_areas.each_with_index do |area, index|

            # 先查特殊区域运费模板是否有记录
            target_template = nil
            area.au_suburb.freight_templates.includes(:default_freight_template).order(:id).each do |exceptional_template|
              # 现在特殊模板的delivery_type都是merchant_delivery, 需要拿默认模板delivery_type的的才行
              if exceptional_template.default_freight_template.merchant_delivery?
                target_template = exceptional_template
                break
              end
            end

            target_template = MagicBean::DefaultFreightTemplate.where(store_id: store&.id).merchant_delivery.order(:id).first unless target_template

            weekdays = time.weekdays.sort.map do |w|
              case w
              when "0"
                "周日"
              when "1"
                "周一"
              when "2"
                "周二"
              when "3"
                "周三"
              when "4"
                "周四"
              when "5"
                "周五"
              when "6"
                "周六"
              end
            end.join(", ")

            if index.zero?
              csv << [time.id, time.name, weekdays, time.time_period.join(", "), area.suburb, area.postal_code, "$#{target_template.free_shipping_amount_in_yuan_num}"]
            else
              csv << [nil, nil, nil, nil, area.suburb, area.postal_code, "$#{target_template.free_shipping_amount_in_yuan_num}"]
            end
          end
        end
      end

      csv_string_with_utf8_bom = "\uFEFF" + csv_string

      f.write(csv_string_with_utf8_bom)
    end
    puts "Data is saved to #{output_file}"
  end
end
