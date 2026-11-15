# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
MagicBean::AdminUser.create(mobile: "13800138000", name: "超级管理员", password: "password") if Rails.env.development?

# if MagicBean::Province.all.empty?
#   File.open Rails.root.join("config", "area-data.json") do |file|
#     area_data = JSON.parse file.read
#     MagicBean::Province.transaction do
#       area_data.each do |province_data|
#         # 1. Create provinces data
#         province = MagicBean::Province.create! name: province_data["name"]

#         province_data["children"].each do |city_data|
#           # 2. Create cities data
#           city = MagicBean::City.create! name: city_data["name"], province: province
#           city_data["children"].each do |county_data|
#             # 3. Create counties data
#             MagicBean::County.create! name: county_data["name"], city: city
#           end
#         end
#       end
#     end
#   end
# end

if MagicBean::DefaultFreightTemplate.all.empty?
  # 1kg以内是4元，2kg8元，
  # 超过2kg按每千克*3+2算
  # 甘肃、宁夏、青海1KG是9，2KG是16，之后续重是7，内蒙古1KG是12，2KG是21，之后续重是9，西藏、新疆1KG是16，2KG是27，之后续重是11
  default_freight_template = MagicBean::DefaultFreightTemplate.create!(
    name: "邮寄默认运费模版",
    first_kg_charge_in_cent: 400,
    second_kg_charge_in_cent: 800,
    continued_weight_charge_in_cent: 300,
    extra_charge_in_cent: 200,
    delivery_type: :express
  )
  default_freight_template.exceptional_freight_templates.create!(
    name: "Albury地区收费",
    type: "MagicBean::ExceptionalFreightTemplate",
    first_kg_charge_in_cent: 900,
    second_kg_charge_in_cent: 1600,
    continued_weight_charge_in_cent: 700,
    au_suburb_ids: [1, 2]
  )
  default_freight_template.exceptional_freight_templates.create!(
    name: "Wodonga地区收费",
    type: "MagicBean::ExceptionalFreightTemplate",
    first_kg_charge_in_cent: 1200,
    second_kg_charge_in_cent: 2100,
    continued_weight_charge_in_cent: 900,
    au_suburb_ids: [3, 4]
  )
end

if MagicBean::SiteConfig.all.empty?
  MagicBean::SiteConfig.create!(
    return_receiver_properties: {
      receiver_name: "黄xx",
      tel_number: "13800138000",
      full_receiver_address: "华强路9号保利克洛维大厦中盈1110"
    },
    customer_service_name: "eBest",
    integral_rules: {
      sign_up_integral: 500,
      suggest_integral: 500,
      inviting_integral: 500,
      integral_received_from_one_yuan: 1,
      integral_deducted_from_one_yuan: 100,
      max_integral_in_one_order: 2000
    },
    direct_refund_reasons: ["我不想要了"],
    after_sale_reasons: ["7天无理由退货", "颜色/图案/款式与描述不符"],
    mall_tips: {
      shop_cart_tips: "全场商品8.8折, 16：00前付款当天发货"
    },
    member_bg_image: "https://picsum.photos/1024/480/?image=55",
    payment_settings: {
      wechat_service_percentage: 1,
      vm_credit_card_service_percentage: 1,
      exchange_rate_rise_percentage: 1,
      unionpay_credit_card_service_percentage: 1,
      credit_card_enable: true,
      omipay_wechat_service_percentage: 1,
      omipay_alipay_service_percentage: 1
    }
  )
end

if MagicBean::CustomPage.all.empty?
  MagicBean::CustomPage.create!(
    name: "首页",
    en_name: "home",
    components: [],
    share_setting_attributes: {
      share_words: "",
      share_cover: "",
      share_background_cover: ""
    }
  )
end

if MagicBean::Page.all.empty?
  # MagicBean::Page.create!(name: "关于我们", kind: "about_us", content: "关于我们页面")
  # MagicBean::Page.create!(name: "联系我们", kind: "contact", content: "联系我们页面")
  MagicBean::Page.create!(name: "会员福利", kind: "member_info", content: "会员福利页面")
  MagicBean::Page.create!(name: "金币规则", kind: "integral_rules", content: "金币规则页面")
end

if MagicBean::AuSuburb.all.empty?
  File.open("config/AU.txt", "r").each do |line|
    suburb = line.gsub(/\n/, "").split("\t")
    MagicBean::AuSuburb.transaction do
      MagicBean::AuSuburb.create!(
        postal_code: suburb[1],
        name: suburb[2],
        state_name: suburb[3],
        state_short_name: suburb[4],
        latitude: suburb[9],
        longitude: suburb[10]
      )
    end
  end
end

if MagicBean::EventPage.all.empty?
  MagicBean::EventPage.create!(
    name: "集 slogen 活动",
    slug: "collect_slogans"
  )
  MagicBean::EventPage.create!(
    name: "七龙珠活动",
    slug: "collect_dragon_balls"
  )
end

unless MagicBean::Nutrition.exists?
  [
    { slug: "energy", name_en: "Energy", name_zh_cn: "能量", name_zh_tw: "能量" },
    { slug: "protein", name_en: "Protein", name_zh_cn: "蛋白质", name_zh_tw: "蛋白質" },
    { slug: "fat, total", name_en: "Fat, total", name_zh_cn: "脂肪总量", name_zh_tw: "脂肪總量" },
    { slug: "saturated", name_en: "Saturated", name_zh_cn: "饱和脂肪", name_zh_tw: "飽和脂肪" },
    { slug: "trans fat", name_en: "Trans fat", name_zh_cn: "反式脂肪", name_zh_tw: "反式脂肪" },
    { slug: "carbohydrate", name_en: "Carbohydrate", name_zh_cn: "碳水化合物", name_zh_tw: "碳水化合物" },
    { slug: "sugars", name_en: "Sugars", name_zh_cn: "糖类", name_zh_tw: "糖類" },
    { slug: "sodium", name_en: "Sodium", name_zh_cn: "钠", name_zh_tw: "鈉" }
  ].each do |attrs|
    nutrition = MagicBean::Nutrition.find_or_initialize_by(slug: attrs[:slug])
    nutrition.update(attrs)
  end
end
