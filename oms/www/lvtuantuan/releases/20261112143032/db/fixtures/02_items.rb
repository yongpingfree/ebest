# frozen_string_literal: true

MagicBean::Item.seed_once(:id,
  {
    id: 1,
    store_id: 1,
    category_id: 2,
    product_id: 1,
    title_zh_cn: "直邮 BOBBI BROWN/芭比布朗 黑管唇膏BRIGHT RASPBERRY 2.3g",
    title_zh_tw: "BRIGHT RASPBERRY 2.3g",
    title_en: "BRIGHT RASPBERRY 2.3g",
    description_zh_cn: "摩登双唇 柔润过冬",
    description_zh_tw: "摩登双唇 柔润过冬",
    description_en: "BRIGHT RASPBERRY 2.3g",
    shared_description_zh_cn: "摩登双唇 柔润过冬",
    shared_description_zh_tw: "摩登双唇 柔润过冬",
    shared_description_en: "BRIGHT RASPBERRY 2.3g",
    price_in_cent: 27800,
    strikethrough_price_in_cent: 28000,
    quantity: 999,
    freight_type: 1,
    fixed_freight: 1000,
    delivery_type: ["merchant_delivery", "express"],
    channels: MagicBean::Item::CHANNEL_ARRAY,
    brand_id: 1,
    qa_and_guarantee_id: 1,
    cover: "http://temp.im/200x200",
    coupon_enabled: true,
    main_images: [
      "http://temp.im/200x200",
      "http://temp.im/200x200",
      "http://temp.im/200x200"
    ],
    detail_images: [
      "http://temp.im/200x200",
      "http://temp.im/200x200",
      "http://temp.im/200x200"
    ]
  },
  {
    id: 2,
    store_id: 1,
    category_id: 15,
    product_id: 1,
    title_zh_cn: "Apple 苹果 iPhone 移动联通电信4G手机",
    title_zh_tw: "Apple iPhone 4G",
    title_en: "Apple iPhone 4G",
    description_zh_cn: "Apple 苹果 iPhone 移动联通电信4G手机",
    description_zh_tw: "Apple 苹果 iPhone 移动联通电信4G手机",
    description_en: "Apple iPhone 4G",
    shared_description_zh_cn: "Apple 苹果 iPhone 移动联通电信4G手机",
    shared_description_zh_tw: "Apple iPhone 4G",
    shared_description_en: "Apple iPhone 4G",
    price_in_cent: 613000,
    strikethrough_price_in_cent: 652800,
    quantity: 999,
    freight_type: 2,
    delivery_type: ["merchant_delivery", "express"],
    channels: MagicBean::Item::CHANNEL_ARRAY,
    default_freight_template_ids: [1],
    brand_id: 2,
    qa_and_guarantee_id: 1,
    coupon_enabled: true,
    cover: "http://temp.im/200x200",
    main_images: [
      "http://temp.im/200x200",
      "http://temp.im/200x200",
      "http://temp.im/200x200"
    ],
    detail_images: [
      "http://temp.im/200x200",
      "http://temp.im/200x200",
      "http://temp.im/200x200"
    ]
  }
)
