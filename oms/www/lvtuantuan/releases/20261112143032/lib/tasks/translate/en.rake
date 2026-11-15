# frozen_string_literal: true

namespace :translate do
  namespace :en do
    task all: [
      :brands_name,
      :categories_name,
      :items,
      :migrate_item_sub_title_to_title_en,
      :coupon_templates,
      :custom_lists
    ]

    desc "翻译品牌名称"
    task brands_name: :environment do
      MagicBean::Brand.find_each do |brand|
        text = brand.name
        eng = EasyTranslate.translate(text, from: :"zh-CN", to: :en)
        brand.assign_attributes(name_en: eng)
        brand.save(validate: false)
      end
    end

    desc "翻译分类名称"
    task categories_name: :environment do
      MagicBean::Category.find_each do |category|
        text = category.name
        eng = EasyTranslate.translate(text, from: :"zh-CN", to: :en)
        category.assign_attributes(name_en: eng)
        category.save(validate: false)
      end
    end

    desc "翻译产品"
    task items: :environment do
      MagicBean::Item.on_sale.find_each do |item|
        item.translated_attribute_names.each do |attr|
          text = item[attr]
          next if text.blank?

          eng = EasyTranslate.translate(text, from: :"zh-CN", to: :en)
          item.assign_attributes("#{attr}_en": eng)
          item.save(validate: false)
        end
      end
    end

    desc "迁移商品的 sub title 到英文标题"
    task migrate_item_sub_title_to_title_en: :environment do
      MagicBean::Item.where.not(sub_title: nil).find_each do |item|
        if item.title_en.blank?
          item.update(title_en: item.sub_title)
        end
      end
    end

    desc "翻译优惠券"
    task coupon_templates: :environment do
      MagicBean::CouponTemplate.find_each do |ct|
        text = ct.title_zh_cn
        hant = Ropencc.conv("s2tw.json", text)
        eng = EasyTranslate.translate(text, from: :"zh-CN", to: :en)
        ct.assign_attributes(title_zh_tw: hant, title_en: eng)
        ct.save(validate: false)
      end
    end

    desc "翻译自定义商品列表"
    task custom_lists: :environment do
      MagicBean::CustomList.find_each do |list|
        text = list.title_zh_cn
        hant = Ropencc.conv("s2tw.json", text)
        eng = EasyTranslate.translate(text, from: :"zh-CN", to: :en)
        list.assign_attributes(title_zh_tw: hant, title_en: eng)
        list.save(validate: false)
      end
    end

    desc "SKU properties and values"
    task sku_properties_and_values: :environment do
      MagicBean::SkuProperty.find_each do |property|
        text = property.text_zh_cn

        next if text.blank?

        eng = EasyTranslate.translate(text, from: :"zh-CN", to: :en)
        property.text_en = eng
        property.save(validate: false)
      end

      MagicBean::SkuValue.find_each do |value|
        text = value.text_zh_cn

        next if text.blank?

        eng = EasyTranslate.translate(text, from: :"zh-CN", to: :en)
        value.text_en = eng
        value.save(validate: false)
      end
    end

    desc "Translate SKU based on excel"
    task :sku_based_on_excel, [:prop_file, :value_file] => :environment do |t, args|
      # header format: ID | 简体中文 | 机翻繁体 | 机翻英文 | 修正英文
      # url: https://docs.qq.com/sheet/DWWFBdGxmRllGemp4?tab=BB08J2
      prop_file = args[:prop_file].to_s
      value_file = args[:value_file].to_s

      next unless File.exists?(prop_file) && File.exists?(value_file)

      {
        "MagicBean::SkuProperty" => prop_file,
        "MagicBean::SkuValue" => value_file
      }.each_pair do |model_name, filepath|
        xlsx = Roo::Spreadsheet.open(filepath, extension: :xlsx)
        model = model_name.constantize

        xlsx.each_row_streaming(pad_cells: true) do |row|
          eng_text = row[4].value
          next if eng_text.blank?

          id = row[0].value.to_i
          record = model.find_by id: id
          next if record.nil?

          record.update(text_en: eng_text)
        end
      end

      puts "Done"
    end
  end
end
