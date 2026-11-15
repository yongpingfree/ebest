# frozen_string_literal: true

namespace :translate do
  namespace :zh_tw do
    desc "Translate all zh_tw"
    task all: [
      :brands_name,
      :categories_name,
      :items,
      :set_items_searchable_attrs,
      :coupon_templates,
      :custom_lists,
      :copy_image_url_of_qa_and_guarantees
    ]

    desc "复制答疑&保障图片 URL"
    task copy_image_url_of_qa_and_guarantees: :environment do
      MagicBean::QaAndGuarantee.find_each do |qa|
        image_url = qa.image_zh_cn
        qa.assign_attributes(image_zh_tw: image_url, image_en: image_url)
        qa.save(validate: false)
      end
    end

    desc "翻译品牌名称"
    task brands_name: :environment do
      MagicBean::Brand.find_each do |brand|
        text = brand.name
        hant = Ropencc.conv("s2tw.json", text)
        brand.assign_attributes(name_zh_tw: hant)
        brand.save(validate: false)
      end
    end

    desc "翻译分类名称"
    task categories_name: :environment do
      MagicBean::Category.find_each do |category|
        text = category.name
        hant = Ropencc.conv("s2tw.json", text)
        category.assign_attributes(name_zh_tw: hant)
        category.save(validate: false)
      end
    end

    desc "翻译产品"
    task items: :environment do
      MagicBean::Item.on_sale.find_each do |item|
        item.translated_attribute_names.each do |attr|
          text = item[attr]
          next if text.blank?

          hant = Ropencc.conv("s2tw.json", text)
          item.assign_attributes("#{attr}_zh_tw": hant)
          item.save(validate: false)
        end
      end
    end

    desc "组合商品的搜索翻译"
    task set_items_searchable_attrs: :environment do
      searchable_attrs = [:title, :description]
      MagicBean::Item.on_sale.find_each do |item|
        searchable_attrs.each do |attr|
          item["translated_searchable_#{attr}"] = [item.send("#{attr}_zh_cn"), item.send("#{attr}_zh_tw"), item.send("#{attr}_en")].compact.join(" ")
        end
        item.save(validate: false)
      end
    end

    desc "翻译优惠券"
    task coupon_templates: :environment do
      MagicBean::CouponTemplate.find_each do |ct|
        text = ct.title_zh_cn
        hant = Ropencc.conv("s2tw.json", text)
        ct.assign_attributes(title_zh_tw: hant)
        ct.save(validate: false)
      end
    end

    desc "翻译自定义商品列表"
    task custom_lists: :environment do
      MagicBean::CustomList.find_each do |list|
        text = list.title_zh_cn
        hant = Ropencc.conv("s2tw.json", text)
        list.assign_attributes(title_zh_tw: hant)
        list.save(validate: false)
      end
    end

    desc "翻译搜索热词"
    task hot_searches: :environment do
      MagicBean::HotSearch.show.find_each do |search|
        text = search.word_zh_cn
        hant = Ropencc.conv("s2tw.json", text)
        eng = EasyTranslate.translate(text, from: :"zh-CN", to: :en)
        search.assign_attributes(word_zh_tw: hant, word_en: eng)
        search.save(validate: false)
      end
    end

    desc "SKU properties and values"
    task sku_properties_and_values: :environment do
      MagicBean::SkuProperty.find_each do |property|
        text = property.text_zh_cn

        next if text.blank?

        hant = Ropencc.conv("s2tw.json", text)
        property.text_zh_tw = hant
        property.save(validate: false)
      end

      MagicBean::SkuValue.find_each do |value|
        text = value.text_zh_cn

        next if text.blank?

        hant = Ropencc.conv("s2tw.json", text)
        value.text_zh_tw = hant
        value.save(validate: false)
      end
    end
  end
end
