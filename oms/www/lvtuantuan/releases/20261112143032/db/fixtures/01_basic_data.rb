# frozen_string_literal: true

MagicBean::Brand.seed_once(:id,
  { id: 1, name_zh_cn: "品牌一", name_zh_tw: "品牌一", name_en: "Brand One" },
  { id: 2, name_zh_cn: "品牌二", name_zh_tw: "品牌二", name_en: "Brand Two" }
)

MagicBean::QaAndGuarantee.seed_once(:id,
  {
    id: 1, title_zh_cn: "模板一", title_zh_tw: "範本一", title_en: "Template 1", web_image: "http://temp.im/750x200",
    image_zh_cn: "http://temp.im/750x200", image_zh_tw: "http://temp.im/750x200", image_en: "http://temp.im/750x200"
  }
)

MagicBean::Category.seed_once(:id,
  # 一级类目
  { id: 1, name_zh_cn: "人气美妆", name_zh_tw: "人氣美妝",name_en: "Popular Beauty", position: 1 },
  # 二级类目
  { id: 2, name_zh_cn: "补水面膜", name_zh_tw: "補水面膜", name_en: "Hydrating Mask", parent_id: 1 },
  { id: 3, name_zh_cn: "唇膏口红", name_zh_tw: "脣膏口紅", name_en: "Lipstick Lipsticks", parent_id: 1 },
  { id: 4, name_zh_cn: "眼部护理", name_zh_tw: "眼部護理", name_en: "Eye Care", parent_id: 1 },
  { id: 5, name_zh_cn: "修容底妆", name_zh_tw: "修容底妝", name_en: "Makeup Fixing Base", parent_id: 1 },
  { id: 6, name_zh_cn: "爽肤水", name_zh_tw: "爽膚水", name_en: "爽肤水",parent_id: 1 },
  { id: 7, name_zh_cn: "精华液", name_zh_tw: "精华液", name_en: "Serums", parent_id: 1 },

  # 一级类目
  { id: 8, name_zh_cn: "母婴健康", name_zh_tw: "母嬰健康", name_en: "Maternal and Child Health", position: 2 },
  # 二级类目
  { id: 9, name_zh_cn: "大牌奶粉", name_zh_tw: "大牌奶粉", name_en: "Big Brand Milk Powder", parent_id: 8 },
  { id: 10, name_zh_cn: "营养辅食", name_zh_tw: "營養輔食", name_en: "Nutritional Supplements", parent_id: 8 },
  { id: 11, name_zh_cn: "孕妈专区", name_zh_tw: "孕媽專區", name_en: "Pregnant Mother Zone", parent_id: 8 },
  { id: 12, name_zh_cn: "居家出行", name_zh_tw: "居家出行", name_en: "Home Travel", parent_id: 8 },
  { id: 13, name_zh_cn: "宝宝护肤", name_zh_tw: "寶寶護膚", name_en: "Baby Skin Care", parent_id: 8 },

  # 一级分类
  { id: 14, name_zh_cn: "数码产品", name_zh_tw: "数码产品", name_en: "数码产品", position: 3 },
  # 二级类目
  { id: 15, name_zh_cn: "智能手机", name_zh_tw: "智能手機", name_en: "Smartphone", parent_id: 14 }
)

MagicBean::SkuProperty.seed_once(:id,
  { id: 1, text_zh_cn: "色号", text_zh_tw: "色號", text_en: "Color" },
  { id: 2, text_zh_cn: "型号", text_zh_tw: "型號", text_en: "Model" },
  { id: 3, text_zh_cn: "机身颜色", text_zh_tw: "機身顏色", text_en: "Color" },
  { id: 4, text_zh_cn: "内存", text_zh_tw: "内存", text_en: "Storage" }
)

MagicBean::SkuValue.seed_once(:id,
  # 口红色号值
  { id: 1, text_zh_cn: "06号 沙漠玫瑰", text_zh_tw: "06號 沙漠玫瑰", text_en: "No. 06 Desert Rose", sku_property_id: 1 },
  { id: 2, text_zh_cn: "13号 罂粟迷情", text_zh_tw: "13號 罌粟迷情", text_en: "No. 13 poppy fascination", sku_property_id: 1 },
  { id: 3, text_zh_cn: "19号 蔷薇花蕾", text_zh_tw: "19號 薔薇花蕾", text_en: "No. 19 Rose Bud", sku_property_id: 1 },
  { id: 4, text_zh_cn: "20号 活力珊瑚", text_zh_tw: "20號 活力珊瑚", text_en: "No. 20 vitality coral", sku_property_id: 1 },

  # iPhone 型号
  { id: 5, text_zh_cn: "iPhone Xs", text_zh_tw: "iPhone Xs", text_en: "iPhone Xs", sku_property_id: 2 },
  { id: 6, text_zh_cn: "iPhone XR", text_zh_tw: "iPhone XR", text_en: "iPhone XR", sku_property_id: 2 },
  { id: 7, text_zh_cn: "iPhone X", text_zh_tw: "iPhone XR", text_en: "iPhone XR", sku_property_id: 2 },
  { id: 8, text_zh_cn: "iPhone 8 Plus", text_zh_tw: "iPhone XR", text_en: "iPhone XR", sku_property_id: 2 },

  # 机身颜色
  { id: 9, text_zh_cn: "银色", text_zh_tw: "銀色", text_en: "Silver", sku_property_id: 3 },
  { id: 10, text_zh_cn: "深空灰色", text_zh_tw: "深空灰色", text_en: "Deep space gray", sku_property_id: 3 },
  { id: 11, text_zh_cn: "金色", text_zh_tw: "金色", text_en: "Gold", sku_property_id: 3 },
  { id: 12, text_zh_cn: "红色", text_zh_tw: "紅色", text_en: "Red", sku_property_id: 3 },

  # 内存
  { id: 13, text_zh_cn: "64G", text_zh_tw: "64G", text_en: "64G", sku_property_id: 4 },
  { id: 14, text_zh_cn: "128G", text_zh_tw: "64G", text_en: "64G", sku_property_id: 4 },
  { id: 15, text_zh_cn: "256G", text_zh_tw: "64G", text_en: "64G", sku_property_id: 4 },
  { id: 16, text_zh_cn: "512G", text_zh_tw: "64G", text_en: "64G", sku_property_id: 4 }
)

MagicBean::Store.seed_once(:id, { id: 1, name: "Sydney", is_default: true })

MagicBean::Product.seed_once(:id,
  {
    id: 1,
    store_id: 1,
    category_id: 2,
    title: "直邮 BOBBI BROWN/芭比布朗 黑管唇膏BRIGHT RASPBERRY 2.3g",
    description: "摩登双唇 柔润过冬",
    shared_description: "摩登双唇 柔润过冬",
    brand_id: 1,
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
