<?php

/*
 * VMS 配置。商品字段定义同时驱动:录入表单、校验、导出 import-items.xlsx。
 * key 与 import-items.xlsx 第 1 行的列名一致。
 *   scope: vendor = 供应商填写, ops = eBest 运营填写, auto = 系统自动生成
 *   type : text | textarea | number | decimal | yesno | select | multi
 */
$yesno = ['是', '否'];

return [
    'store_id' => env('VMS_STORE_ID', 2),

    'image_disk' => env('VMS_IMAGE_DISK', 'public'),
    'image_cdn_host' => env('VMS_IMAGE_CDN_HOST', 'cdn.minimall.donkibuy.com'),
    'image_max_kb' => 5120,
    // .env 中 AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY 存 base64 编码值(echo -n '<值>' | base64),上传时由 ImageService 解码
    's3_raw' => ['key' => env('AWS_ACCESS_KEY_ID'), 'secret' => env('AWS_SECRET_ACCESS_KEY')],

    // 图片规格(宽 x 高,0 表示不限制;ratio 表示只要求宽高比)
    'image_kinds' => [
        'cover' => ['label' => '封面图', 'required' => true, 'single' => true, 'width' => 750, 'height' => 750, 'hint' => '750×750,必填'],
        'share_cover' => ['label' => '分享海报图', 'required' => false, 'single' => true, 'width' => 375, 'height' => 0, 'max_height' => 466, 'hint' => '宽 375,高度自适应,最大高 466,可选'],
        'main_images' => ['label' => '产品主图', 'required' => true, 'single' => false, 'width' => 750, 'height' => 750, 'hint' => '750:750(正方形),必填,可多张'],
        'detail_images' => ['label' => '产品详情图', 'required' => true, 'single' => false, 'width' => 375, 'height' => 0, 'hint' => '宽 375,高度自适应,必填,可多张'],
        'sku_image' => ['label' => 'SKU 图', 'required' => true, 'single' => true, 'width' => 0, 'height' => 0, 'hint' => '必填'],
    ],

    'item_fields' => [
        ['key' => 'title_zh_cn', 'label' => '中文标题', 'type' => 'text', 'required' => true, 'scope' => 'vendor', 'group' => '基本信息'],
        ['key' => 'title_en', 'label' => '英文标题', 'type' => 'text', 'required' => false, 'scope' => 'vendor', 'group' => '基本信息'],
        ['key' => 'short_title', 'label' => '短标题', 'type' => 'text', 'required' => false, 'scope' => 'vendor', 'group' => '基本信息'],
        ['key' => 'description_zh_cn', 'label' => '商品描述', 'type' => 'textarea', 'required' => false, 'scope' => 'vendor', 'group' => '基本信息'],
        ['key' => 'shared_description_zh_cn', 'label' => '分享描述', 'type' => 'textarea', 'required' => false, 'scope' => 'vendor', 'group' => '基本信息'],
        ['key' => 'tag_list', 'label' => '标签(分号隔开)', 'type' => 'text', 'required' => false, 'scope' => 'vendor', 'group' => '基本信息'],
        ['key' => 'storage_method', 'label' => '存储方式', 'type' => 'select', 'options' => ['常温', '冷藏', '冷冻', '其他', '/'], 'required' => false, 'scope' => 'vendor', 'group' => '基本信息'],

        ['key' => 'sku_no', 'label' => '商品编码(货号,唯一)', 'type' => 'text', 'required' => true, 'scope' => 'vendor', 'group' => 'SKU 与价格'],
        ['key' => 'barcode', 'label' => '条形码', 'type' => 'text', 'required' => false, 'scope' => 'vendor', 'group' => 'SKU 与价格'],
        ['key' => 'properties_arr', 'label' => '规格(格式 规格名:规格值,多个用分号隔开)', 'type' => 'text', 'required' => true, 'scope' => 'vendor', 'group' => 'SKU 与价格', 'placeholder' => '规格:500g'],
        ['key' => 'price_in_yuan', 'label' => '价格(AUD)', 'type' => 'decimal', 'required' => true, 'scope' => 'vendor', 'group' => 'SKU 与价格'],
        ['key' => 'strikethrough_price_in_yuan', 'label' => '划线价', 'type' => 'decimal', 'required' => false, 'scope' => 'vendor', 'group' => 'SKU 与价格'],
        ['key' => 'discount_quantity', 'label' => '购买数量大于等于(折扣)', 'type' => 'number', 'required' => false, 'scope' => 'vendor', 'group' => 'SKU 与价格'],
        ['key' => 'discount_price_in_yuan', 'label' => '折扣价格', 'type' => 'decimal', 'required' => false, 'scope' => 'vendor', 'group' => 'SKU 与价格'],
        ['key' => 'ae_price_in_yuan', 'label' => 'AE 价格', 'type' => 'decimal', 'required' => false, 'scope' => 'vendor', 'group' => 'SKU 与价格'],
        ['key' => 'quantity', 'label' => '上架数量(库存)', 'type' => 'number', 'required' => true, 'scope' => 'vendor', 'group' => 'SKU 与价格'],
        ['key' => 'gst_percent', 'label' => 'GST %', 'type' => 'select', 'options' => ['10', '0'], 'required' => true, 'default' => '10', 'scope' => 'vendor', 'group' => 'SKU 与价格'],
        ['key' => 'marketing_mode', 'label' => '营销模式', 'type' => 'select', 'options' => ['自营', '寄售', '平台'], 'required' => false, 'default' => '自营', 'scope' => 'vendor', 'group' => 'SKU 与价格'],

        ['key' => 'delivery_type', 'label' => '期望送货/配送方式', 'type' => 'multi', 'options' => ['商家配送', '自提', '快递'], 'required' => true, 'default' => '商家配送', 'scope' => 'vendor', 'group' => '销售与配送'],
        ['key' => 'channels', 'label' => '销售平台', 'type' => 'multi', 'options' => ['APP', '小程序', 'Web网站', 'Shopline', 'Aliexpress'], 'required' => true, 'default' => 'APP;小程序;Web网站', 'scope' => 'vendor', 'group' => '销售与配送'],
        ['key' => 'buy_quota', 'label' => '限购数', 'type' => 'number', 'required' => true, 'default' => '99', 'scope' => 'vendor', 'group' => '销售与配送'],
        ['key' => 'buy_quota_days', 'label' => '限购周期(天)', 'type' => 'number', 'required' => true, 'default' => '1', 'scope' => 'vendor', 'group' => '销售与配送'],
        ['key' => 'is_presell', 'label' => '是否预售', 'type' => 'yesno', 'options' => $yesno, 'required' => false, 'default' => '否', 'scope' => 'vendor', 'group' => '销售与配送'],
        ['key' => 'presell_end_at', 'label' => '预售结束时间(墨尔本时区)', 'type' => 'text', 'required' => false, 'required_if' => ['is_presell' => '是'], 'scope' => 'vendor', 'group' => '销售与配送'],
        ['key' => 'presell_dispatch_on', 'label' => '预售可派送最早日期', 'type' => 'text', 'required' => false, 'required_if' => ['is_presell' => '是'], 'scope' => 'vendor', 'group' => '销售与配送'],
        ['key' => 'latest_presell_dispatch_on', 'label' => '预售可派送最晚日期', 'type' => 'text', 'required' => false, 'required_if' => ['is_presell' => '是'], 'scope' => 'vendor', 'group' => '销售与配送'],
        ['key' => 'is_virtual', 'label' => '是否虚拟库存商品', 'type' => 'yesno', 'options' => $yesno, 'required' => false, 'default' => '否', 'scope' => 'vendor', 'group' => '销售与配送'],
        ['key' => 'coupon_enabled', 'label' => '是否可用优惠券', 'type' => 'yesno', 'options' => $yesno, 'required' => false, 'default' => '是', 'scope' => 'vendor', 'group' => '销售与配送'],
        ['key' => 'is_seasonal', 'label' => '是否时令商品', 'type' => 'yesno', 'options' => $yesno, 'required' => false, 'default' => '否', 'scope' => 'vendor', 'group' => '销售与配送'],
        ['key' => 'is_fresh_daily', 'label' => '是否每日鲜商品', 'type' => 'yesno', 'options' => $yesno, 'required' => false, 'default' => '否', 'scope' => 'vendor', 'group' => '销售与配送'],
        ['key' => 'is_special', 'label' => '是否特品', 'type' => 'yesno', 'options' => $yesno, 'required' => false, 'default' => '否', 'scope' => 'vendor', 'group' => '销售与配送'],

        ['key' => 'length_in_cm', 'label' => '长度(cm)', 'type' => 'decimal', 'required' => false, 'scope' => 'vendor', 'group' => '尺寸重量'],
        ['key' => 'width_in_cm', 'label' => '宽度(cm)', 'type' => 'decimal', 'required' => false, 'scope' => 'vendor', 'group' => '尺寸重量'],
        ['key' => 'height_in_cm', 'label' => '高度(cm)', 'type' => 'decimal', 'required' => false, 'scope' => 'vendor', 'group' => '尺寸重量'],
        ['key' => 'weight_in_gram', 'label' => '重量(g)', 'type' => 'decimal', 'required' => false, 'scope' => 'vendor', 'group' => '尺寸重量'],

        // eBest 运营填写(供应商不可见、不可改)
        ['key' => 'leader', 'label' => '负责人', 'type' => 'text', 'required' => false, 'scope' => 'ops', 'group' => '运营填写'],
        ['key' => 'category_id', 'label' => '主产品二级分类 id', 'type' => 'text', 'required' => false, 'scope' => 'ops', 'group' => '运营填写'],
        ['key' => 'minor_category_id', 'label' => '次产品二级分类 id', 'type' => 'text', 'required' => false, 'scope' => 'ops', 'group' => '运营填写'],
        ['key' => 'brand_id', 'label' => '品牌 id', 'type' => 'text', 'required' => false, 'scope' => 'ops', 'group' => '运营填写'],
        ['key' => 'qa_and_guarantee_id', 'label' => '答疑&保障 id', 'type' => 'text', 'required' => false, 'scope' => 'ops', 'group' => '运营填写'],
        ['key' => 'sales_count_offset', 'label' => '基础销量数', 'type' => 'number', 'required' => false, 'scope' => 'ops', 'group' => '运营填写'],
        ['key' => 'default_freight_template_ids', 'label' => '运费模板 id(分号隔开)', 'type' => 'text', 'required' => false, 'scope' => 'ops', 'group' => '运营填写'],
    ],

    // import-items.xlsx 中由系统自动生成的列
    'item_auto_columns' => ['store_id', 'item_no', 'shoppingunit', 'cover', 'share_cover', 'main_images', 'detail_images', 'sku_image'],

    'marketing_modes' => ['自营', '寄售', '平台'],
    'delivery_modes' => [
        'vendor' => '供应商配送(供应商自行建单,无需 eBest 审核)',
        'ebest' => 'eBest 配送(eBest 收货确认后建单,仓库审核)',
        'jit' => '次日送仓 JIT(每日送货后建单,仓库审核)',
    ],
    'gst_rates' => ['10', '0'],
    'virtual_qty' => 999999,

    'verification_ttl_minutes' => 15,
    'verification_max_attempts' => 5,
];
