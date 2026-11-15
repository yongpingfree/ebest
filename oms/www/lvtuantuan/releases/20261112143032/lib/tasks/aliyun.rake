# frozen_string_literal: true

namespace :aliyun do
  # rake aliyun:migrate_domain[orkzkilyn.bkt.clouddn.com,example.com]
  desc "migrate aliyun oss domain"
  task :migrate_domain, [:old_value, :new_value] => :environment do |t, args|
    old_value = args[:old_value]
    new_value =  args[:new_value]
    raise "old_value or new_value missing" if old_value.blank? || new_value.blank?

    connection = ActiveRecord::Base.connection

    tables = connection.tables.reject { |table| ["schema_info", "schema_migrations", "freight_templates_items"].include?(table) }.sort

    tables.each do |table|
      p "table: #{table}"
      quoted_table_name = connection.quote_table_name(table)
      column_names = connection.columns(table).map(&:name)
      primary_key = connection.primary_key(table)
      quoted_primary_key = connection.quote_column_name(primary_key)

      records_per_page=1000
      total_count = connection.select_value("SELECT COUNT(*) FROM #{quoted_table_name}")
      pages = (total_count.to_f / records_per_page).ceil - 1

      (0..pages).to_a.each do |page|
        query = Arel::Table.new(table).order(primary_key).skip(records_per_page*page).take(records_per_page).project(Arel.sql("*"))
        records = connection.select_all(query.to_sql)

        records.rows.each do |row|
          quoted_values = row.map { |c| connection.quote(c) }
          primary_key_value = nil
          sets = records.columns.map.with_index do |column_name, index|
            primary_key_value = quoted_values[index] if column_name == primary_key

            quoted_value = quoted_values[index]
            if quoted_value.include?(old_value)
              p "#{primary_key}: #{primary_key_value} - #{column_name}"
              quoted_value = quoted_value.gsub(old_value, new_value)
              connection.execute("UPDATE #{quoted_table_name} SET #{connection.quote_column_name(column_name)} = #{quoted_value} WHERE #{quoted_primary_key} = #{primary_key_value}")
            end
          end
        end
      end
    end
  end

  # rake aliyun:migrate_domain[orkzkilyn.bkt.clouddn.com,example.com]
  desc "migrate aliyun oss watermark"
  task migrate_watermark: :environment do |t, args|
    ActiveRecord::Base.transaction do
      MagicBean::Category.find_each do |item|
        item.icon = add_watermark_to(item.icon)
        item.save(validate: false)
      end
      MagicBean::CouponPackage.find_each do |item|
        item.cover = add_watermark_to(item.cover)
        item.save(validate: false)
      end
      MagicBean::Page.find_each do |item|
        item.cover = add_watermark_to(item.cover)
        item.save(validate: false)
      end
      MagicBean::QaAndGuarantee.find_each do |item|
        item.image = add_watermark_to(item.image)
        item.save(validate: false)
      end
      MagicBean::StockKeepingUnit.find_each do |item|
        item.image = add_watermark_to(item.image)
        item.save(validate: false)
      end
      MagicBean::OrderItem.find_each do |item|
        item.image = add_watermark_to(item.image)
        item.save(validate: false)
      end
      MagicBean::PagePopup.find_each do |item|
        item.image = add_watermark_to(item.image)
        item.save(validate: false)
      end
      MagicBean::CouponTemplate.find_each do |item|
        item.details_image = add_watermark_to(item.details_image)
        item.expired_image = add_watermark_to(item.expired_image)
        item.ticket_image = add_watermark_to(item.ticket_image)
        item.save(validate: false)
      end
      MagicBean::AfterSale.find_each do |item|
        item.images = item.images.map do |image|
          add_watermark_to(image)
        end
        item.save(validate: false)
      end
      MagicBean::Comment.find_each do |item|
        item.images = item.images.map do |image|
          add_watermark_to(image)
        end
        item.save(validate: false)
      end
      MagicBean::Item.find_each do |item|
        item.cover = add_watermark_to(item.cover)
        item.main_images = item.main_images.map do |image|
          add_watermark_to(image)
        end
        item.detail_images = item.detail_images.map do |image|
          add_watermark_to(image)
        end
        item.save(validate: false)
      end
    end
  end

  # 1. 如果没有做图偏压缩，会先做处理
  # 2. 如果已经加过水印则会替换成新的水印
  def add_watermark_to(url)
    return url if url.blank?

    url = url + "?x-oss-process=image/resize,w_750/quality,q_80" unless url.include?("?x-oss-process")

    if url.include?("watermark")
      url.split("watermark")[0] + "/" + MagicBean::SiteConfig.default_config&.watermark_serialized
    else
      url + "/" + MagicBean::SiteConfig.default_config&.watermark_serialized
    end
  end
end
