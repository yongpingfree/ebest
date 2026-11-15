# frozen_string_literal: true
# descriptive_statistics里面的sum/max/min等方法会与rails的方法冲突，所以只在这个文件里面require
# 且使用的数组需要extend(DescriptiveStatistics)
require "descriptive_statistics/safe"

class CalculateSkuLevelsJob < ApplicationJob
  queue_as :default

  include ::BeansAdmin::Helpers::SkuSalesHelper

  # 所有计算都精确到小数后5位，避免计算出现误差
  def perform
    # 每晚清空所有GMV和GP level, 避免影响计算结果
    MagicBean::StockKeepingUnit.ransack(item_ae_drop_shipper_eq: false).result.update_all(gmv_sku_level: nil, gp_sku_level: nil)

    MagicBean::Store.all.each do |store|
      # 计算过去30天内有销量的SKU
      start_at = 30.days.ago.beginning_of_day
      end_at = Time.current.beginning_of_day
      order_items_collection = MagicBean::OrderItem.where(
        order_id: MagicBean::Order.paid.where(created_at: start_at..end_at, store_id: store.id).select(:id),
        item_id: MagicBean::Item.where(is_virtual: false, ae_drop_shipper: false).select(:id)
      )

      thirty_days_sale_skus = order_items_collection.group(:stock_keeping_unit_id).sum(:quantity).sort_by { |_k,v| v }.reverse.to_h.keys

      all_sku_sale_amount_hash = order_items_collection.group(:stock_keeping_unit_id).sum(:amount_in_cent)
      all_sku_sale_quantity_hash = order_items_collection.group(:stock_keeping_unit_id).sum(:quantity)

      sku_return_hash = sales_collections_returns_data(thirty_days_sale_skus, { "order_created_at_lteq" => end_at, "order_created_at_gteq" => start_at, "ae_drop_shipper" => false })

      # 毛利率需要遍历一遍sku才能计算出所有毛利率，用于计算出gp平均值和标准差，之后需要再遍历一遍才能计算出gp_sku_level
      gross_profits_hash = {}
      # 将sku按照category_id分组
      category_skus_hash = {}

      # 先计算出所有new和not available的SKU, 其他计算需要排除这两种SKU
      MagicBean::StockKeepingUnit.includes(:newest_supplier, :item).where(store_id: store.id).ransack(item_ae_drop_shipper_eq: false).result.find_each do |sku|
        gmv_sku_level, gp_sku_level = nil
        category_skus_hash[sku.item.parent_category_id] ||= []

        if sku.first_sale_at.blank?
          # 没有上架售卖过的 SKU 等级为 not_available
          gmv_sku_level = "not_available"
          gp_sku_level = "not_available"
        elsif sku.first_sale_at > 45.days.ago
          # SKU首次上架售卖时间小于45天，则GMV和GP都为new
          gmv_sku_level = "new"
          gp_sku_level = "new"
        elsif thirty_days_sale_skus.exclude?(sku.id)
          # 特品: 过去30天内没有销量的SKU等级为not_available; 非特品: 过去30天内没有销量且库存为0的SKU等级为not_available
          if sku.is_special || (!sku.is_special && sku.quantity.zero?)
            gmv_sku_level = "not_available"
            gp_sku_level = "not_available"
          else
            gmv_sku_level = "C"
            gp_sku_level = "C"
            # 非特品有库存需要参与
            category_skus_hash[sku.item.parent_category_id] << sku.id
          end
        else
          category_skus_hash[sku.item.parent_category_id] << sku.id

          sale_amount = all_sku_sale_amount_hash[sku.id]
          sale_quantity = all_sku_sale_quantity_hash[sku.id]

          # TODO: 要跟Denis确认没有销量、销量等于退货数量等情况要不要加入计算gross_profit
          supplier_cost = sku.newest_supplier&.cost_in_cent
          if supplier_cost.present?
            return_hash = sku_return_hash["#{sku.id}"]
            sum_after_sale_quantity = return_hash.present? ? return_hash[:sum_after_sale_quantity] : 0
            sum_after_sale_in_cent = return_hash.present? ? (return_hash[:sum_after_sale_in_yuan] * 100).round : 0

            if sale_quantity == sum_after_sale_quantity
              gp_sku_level = "not_available"
            elsif sale_quantity < sum_after_sale_quantity || sale_amount < sum_after_sale_in_cent
              # 如果销售量小于退货量或者销售额小于退货额，则GP等级为
              gp_sku_level = "C"
            else
              # 计算毛利润: [(總銷售額-退貨金額)/(總銷售量-退貨數量)-COGS]*(總銷售量-退貨數量), 保留5位小数
              gross_profit = (((sale_amount - sum_after_sale_in_cent) / (sale_quantity - sum_after_sale_quantity).to_f - supplier_cost) * (sale_quantity - sum_after_sale_quantity)).round(5)
              gross_profits_hash[sku.item.parent_category_id] ||= {}
              gross_profits_hash[sku.item.parent_category_id][sku.id] = gross_profit
            end
          end
        end

        sku.update_columns gmv_sku_level: gmv_sku_level, gp_sku_level: gp_sku_level
      end

      # gmv和gp new 和 not_available的规则基本是一样的，gp多了一种情况，但不影响到计算结果，所以只需要过滤掉gmv即可
      # where.not会把nil也过滤掉
      MagicBean::StockKeepingUnit.includes(:item).where(id: thirty_days_sale_skus, gmv_sku_level: [nil, "A", "B", "C"]).ransack(item_ae_drop_shipper_eq: false).result.find_each do |sku|
        sale_amount = all_sku_sale_amount_hash[sku.id]
        sale_quantity = all_sku_sale_quantity_hash[sku.id]
        # 计算一级分类下所有非new/not_available SKU的销售额和销售量

        parent_category_sale_amount_arr, parent_category_sale_quantity_arr = [], []
        category_skus_hash[sku.item.parent_category_id].each do |sku_id|
          parent_category_sale_amount_arr << all_sku_sale_amount_hash[sku_id].to_i
          parent_category_sale_quantity_arr << all_sku_sale_quantity_hash[sku_id].to_i
        end

        parent_category_sale_amount_arr = parent_category_sale_amount_arr.extend(DescriptiveStatistics)
        parent_category_sale_quantity_arr = parent_category_sale_quantity_arr.extend(DescriptiveStatistics)

        # 销售额占比: SKU销售总额/一级分类销售总额
        # 销售量占比: SKU销售总量/一级分类销售总量
        sale_amount_percentage = (sale_amount / parent_category_sale_amount_arr.sum.to_f).round(5)
        sale_quantity_percentage = (sale_quantity / parent_category_sale_quantity_arr.sum.to_f).round(5)

        # 一级分类下所有SKU的销售额的平均值和标准差
        parent_category_sale_amount_mean = (parent_category_sale_amount_arr.mean || 0).round(5)
        parent_category_sale_amount_deviation = (parent_category_sale_amount_arr.standard_deviation || 0).round(5)

        gmv_sku_level = if sale_amount_percentage > sale_quantity_percentage && sale_amount > (parent_category_sale_amount_mean + 2 * parent_category_sale_amount_deviation)
          "A"
        elsif sale_amount >= parent_category_sale_amount_mean
          "B"
        else
          "C"
        end

        parent_category_gross_profits_hash = gross_profits_hash[sku.item.parent_category_id]
        gp_sku_level = if parent_category_gross_profits_hash.blank? || parent_category_gross_profits_hash[sku.id].blank?
          sku.gp_sku_level
        else
          # 参与计算的所有一级分类有毛利率数据的SKU平均值和标准差
          gross_profits_arr = parent_category_gross_profits_hash.values.extend(DescriptiveStatistics)
          gross_profits_mean = (gross_profits_arr.mean || 0).round(5)
          gross_profit_deviation = (gross_profits_arr.standard_deviation || 0).round(5)

          if parent_category_gross_profits_hash[sku.id] > (gross_profits_mean + 2 * gross_profit_deviation)
            "A"
          elsif sale_amount >= gross_profits_mean
            "B"
          else
            "C"
          end
        end

        sku.update_columns gmv_sku_level: gmv_sku_level, gp_sku_level: gp_sku_level
      end
    end
  end
end
