# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2026_10_27_000001) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "hstore"
  enable_extension "plpgsql"

  create_table "actions", force: :cascade do |t|
    t.string "action_type", null: false
    t.string "action_option"
    t.string "target_type"
    t.integer "target_id"
    t.string "user_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["target_type", "target_id", "action_type"], name: "index_actions_on_target_type_and_target_id_and_action_type"
    t.index ["user_type", "user_id", "action_type"], name: "index_actions_on_user_type_and_user_id_and_action_type"
  end

  create_table "addresses", force: :cascade do |t|
    t.string "detail_info"
    t.string "tel_number"
    t.string "first_name"
    t.string "postal_code"
    t.boolean "is_default", default: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "google_place_id"
    t.string "province_name"
    t.string "city_name"
    t.string "email"
    t.string "street"
    t.string "street_number"
    t.string "company_name"
    t.string "alias_name", comment: "地址信息名称"
    t.string "last_name"
    t.string "unit_number"
    t.string "remark", comment: "备注"
    t.integer "housing_type"
    t.index ["user_id"], name: "index_addresses_on_user_id"
  end

  create_table "admin_assign_integral_records", force: :cascade do |t|
    t.bigint "admin_user_id"
    t.bigint "member_id"
    t.bigint "store_id"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_user_id"], name: "index_admin_assign_integral_records_on_admin_user_id"
    t.index ["member_id"], name: "index_admin_assign_integral_records_on_member_id"
    t.index ["store_id"], name: "index_admin_assign_integral_records_on_store_id"
  end

  create_table "admin_user_stores", force: :cascade do |t|
    t.bigint "store_id"
    t.bigint "admin_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_user_id"], name: "index_admin_user_stores_on_admin_user_id"
    t.index ["store_id"], name: "index_admin_user_stores_on_store_id"
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "name"
    t.string "mobile"
    t.integer "state", default: 1
    t.integer "role", default: 1
    t.bigint "creator_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email"
    t.string "password_digest"
    t.boolean "receive_notify_email", default: false
    t.string "permissions", default: [], array: true
    t.integer "can_read_category_ids", default: [], array: true
    t.bigint "role_template_id"
    t.integer "failed_attempts", default: 0
    t.datetime "locked_at"
    t.index ["creator_id"], name: "index_admin_users_on_creator_id"
    t.index ["mobile"], name: "index_admin_users_on_mobile"
    t.index ["role_template_id"], name: "index_admin_users_on_role_template_id"
  end

  create_table "ae_categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "ae_id", null: false
    t.jsonb "product_required_attributes"
    t.jsonb "sku_attributes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ae_id"], name: "index_ae_categories_on_ae_id"
  end

  create_table "ae_drop_shipper_orders", force: :cascade do |t|
    t.bigint "order_id"
    t.string "ae_order_no"
    t.string "order_paidtime"
    t.string "gmt_create", comment: "AE订单创建时间"
    t.string "order_status"
    t.string "logistics_status"
    t.decimal "order_amount", precision: 12, scale: 2, comment: "订单总金额, 单位: AUD"
    t.jsonb "child_order_list", default: [], comment: "订单项信息"
    t.jsonb "store_info", default: {}, comment: "AE店铺信息"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_ae_drop_shipper_orders_on_order_id"
  end

  create_table "after_sales", force: :cascade do |t|
    t.string "refund_no"
    t.integer "after_sale_type", default: 1
    t.integer "status", default: 1
    t.datetime "agreed_at"
    t.string "reason"
    t.integer "amount_in_cent"
    t.bigint "user_id"
    t.bigint "order_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "logistic_no"
    t.string "logistic_company"
    t.integer "total_quantity", default: 0, null: false
    t.string "images", default: [], array: true
    t.string "seller_reply"
    t.string "return_no", comment: "erp退换货单号"
    t.datetime "due_time"
    t.integer "return_integral_amount", default: 0
    t.integer "original_amount_in_cent"
    t.integer "channel"
    t.string "payment_type"
    t.bigint "store_id"
    t.integer "applicant_type", default: 1, comment: "申请人类型"
    t.integer "return_gift_card_amount_in_cent", default: 0
    t.integer "return_coupon_amount_in_cent", default: 0
    t.integer "return_type", default: 1
    t.string "internal_reason", comment: "内部原因"
    t.string "department", comment: "责任部门"
    t.text "audit_explain", comment: "审核说明"
    t.string "audit_images", comment: "审核图片", array: true
    t.string "audit_video", comment: "审核视频"
    t.string "additional_information", comment: "补充说明"
    t.boolean "is_real_claim", default: false, comment: "是否真实理赔"
    t.bigint "lastest_operator_id"
    t.index ["lastest_operator_id"], name: "index_after_sales_on_lastest_operator_id"
    t.index ["order_id"], name: "index_after_sales_on_order_id"
    t.index ["refund_no"], name: "index_after_sales_on_refund_no", unique: true
    t.index ["store_id"], name: "index_after_sales_on_store_id"
    t.index ["user_id"], name: "index_after_sales_on_user_id"
  end

  create_table "after_sales_order_items", force: :cascade do |t|
    t.bigint "order_item_id"
    t.bigint "after_sale_id"
    t.integer "quantity", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "real_amount_in_cent", default: 0
    t.integer "cash_amount_in_cent", default: 0, comment: "实际退款现金($)"
    t.integer "service_amount_in_cent", default: 0, comment: "实际手续费($)"
    t.integer "cost_integral", default: 0, comment: "实际金币数量"
    t.integer "gift_card_amount_in_cent", default: 0, comment: "实际礼品卡($)"
    t.boolean "contain_remainder", default: false, comment: "退款各项金额是否包含余数"
    t.integer "max_service_amount_in_cent", default: 0
    t.integer "max_cost_integral", default: 0
    t.integer "max_gift_card_amount_in_cent", default: 0
    t.integer "max_cash_amount_in_cent", default: 0
    t.integer "original_real_amount_in_cent", default: 0, comment: "最初的优惠金额"
    t.integer "ae_gst_amount_in_cent", default: 0
    t.integer "max_ae_gst_amount_in_cent", default: 0
    t.index ["after_sale_id"], name: "index_after_sales_order_items_on_after_sale_id"
    t.index ["order_item_id"], name: "index_after_sales_order_items_on_order_item_id"
  end

  create_table "age_verification_translations", force: :cascade do |t|
    t.bigint "age_verification_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.string "content"
    t.index ["age_verification_id"], name: "index_age_verification_translations_on_age_verification_id"
    t.index ["locale"], name: "index_age_verification_translations_on_locale"
  end

  create_table "age_verifications", force: :cascade do |t|
    t.bigint "parent_category_id"
    t.string "image"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "parent_web_category_id"
    t.index ["parent_category_id"], name: "index_age_verifications_on_parent_category_id"
    t.index ["parent_web_category_id"], name: "index_age_verifications_on_parent_web_category_id"
  end

  create_table "app_download_channels", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.string "qrcode"
    t.integer "ios_views_count", default: 0
    t.integer "android_views_count", default: 0
    t.integer "other_views_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "app_text_messages", force: :cascade do |t|
    t.string "title", null: false
    t.string "content", null: false
    t.datetime "read_at"
    t.integer "kind", null: false
    t.bigint "user_id"
    t.bigint "admin_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "target_type"
    t.bigint "target_id"
    t.index ["admin_user_id"], name: "index_app_text_messages_on_admin_user_id"
    t.index ["target_id", "target_type"], name: "index_app_text_messages_on_target_attrs"
    t.index ["user_id"], name: "index_app_text_messages_on_user_id"
  end

  create_table "au_suburb_freight_templates", force: :cascade do |t|
    t.bigint "au_suburb_id"
    t.bigint "freight_template_id"
    t.index ["au_suburb_id"], name: "index_au_suburb_freight_templates_on_au_suburb_id"
    t.index ["freight_template_id"], name: "index_au_suburb_freight_templates_on_freight_template_id"
  end

  create_table "au_suburbs", force: :cascade do |t|
    t.string "name"
    t.string "state_name"
    t.string "state_short_name"
    t.string "postal_code"
    t.float "latitude"
    t.float "longitude"
    t.bigint "store_id"
    t.index ["name"], name: "index_au_suburbs_on_name"
    t.index ["postal_code"], name: "index_au_suburbs_on_postal_code"
    t.index ["store_id"], name: "index_au_suburbs_on_store_id"
  end

  create_table "auction_activities", force: :cascade do |t|
    t.string "cover", null: false
    t.datetime "start_at", null: false
    t.datetime "default_end_at", null: false
    t.boolean "auto_renewal_end_at", default: false, null: false
    t.datetime "final_end_at"
    t.datetime "publish_at"
    t.integer "state", default: 0, null: false
    t.integer "starting_price_in_cent", null: false, comment: "起拍价"
    t.integer "bidding_increments_in_cent", null: false, comment: "出价最小增额"
    t.integer "reserve_price_in_cent", comment: "底价"
    t.integer "directly_purchase_price_in_cent", comment: "直接购买价"
    t.string "detail_images", default: [], comment: "主图", array: true
    t.string "main_images", default: [], comment: "详情图", array: true
    t.bigint "category_id"
    t.bigint "parent_category_id"
    t.bigint "minor_category_id"
    t.bigint "minor_parent_category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "store_id"
    t.bigint "best_bid_id"
    t.integer "best_bid_amount_in_cent"
    t.integer "bids_count", default: 0
    t.integer "automatic_bids_count", default: 0
    t.bigint "best_automatic_bid_id"
    t.bigint "item_id"
    t.bigint "stock_keeping_unit_id"
    t.string "no", null: false
    t.bigint "order_id"
    t.bigint "brand_id"
    t.bigint "qa_and_guarantee_id"
    t.index ["best_automatic_bid_id"], name: "index_auction_activities_on_best_automatic_bid_id"
    t.index ["best_bid_id"], name: "index_auction_activities_on_best_bid_id"
    t.index ["brand_id"], name: "index_auction_activities_on_brand_id"
    t.index ["category_id"], name: "index_auction_activities_on_category_id"
    t.index ["item_id"], name: "index_auction_activities_on_item_id"
    t.index ["minor_category_id"], name: "index_auction_activities_on_minor_category_id"
    t.index ["minor_parent_category_id"], name: "index_auction_activities_on_minor_parent_category_id"
    t.index ["no"], name: "index_auction_activities_on_no", unique: true
    t.index ["order_id"], name: "index_auction_activities_on_order_id"
    t.index ["parent_category_id"], name: "index_auction_activities_on_parent_category_id"
    t.index ["qa_and_guarantee_id"], name: "index_auction_activities_on_qa_and_guarantee_id"
    t.index ["stock_keeping_unit_id"], name: "index_auction_activities_on_stock_keeping_unit_id"
    t.index ["store_id"], name: "index_auction_activities_on_store_id"
  end

  create_table "auction_activity_participations", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "auction_activity_id"
    t.integer "state", default: 2, null: false
    t.bigint "auction_order_id"
    t.bigint "store_id"
    t.integer "amount_in_cent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auction_activity_id"], name: "index_auction_activity_participations_on_auction_activity_id"
    t.index ["auction_order_id"], name: "index_auction_activity_participations_on_auction_order_id"
    t.index ["store_id"], name: "index_auction_activity_participations_on_store_id"
    t.index ["user_id", "auction_activity_id"], name: "index_activity_participations_on_user_id_and_activity_id", unique: true
    t.index ["user_id"], name: "index_auction_activity_participations_on_user_id"
  end

  create_table "auction_activity_translations", force: :cascade do |t|
    t.bigint "auction_activity_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.string "description"
    t.index ["auction_activity_id"], name: "index_auction_activity_translations_on_auction_activity_id"
    t.index ["locale"], name: "index_auction_activity_translations_on_locale"
  end

  create_table "auction_automatic_bids", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "auction_activity_id"
    t.integer "amount_limit_in_cent", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auction_activity_id", "amount_limit_in_cent"], name: "index_automatic_bids_on_auction_activity_id_and_amount_limit", unique: true
    t.index ["auction_activity_id"], name: "index_auction_automatic_bids_on_auction_activity_id"
    t.index ["user_id"], name: "index_auction_automatic_bids_on_user_id"
  end

  create_table "auction_bids", force: :cascade do |t|
    t.integer "kind", default: 0, null: false
    t.bigint "user_id"
    t.bigint "auction_activity_id"
    t.bigint "member_id"
    t.integer "amount_in_cent", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auction_activity_id", "amount_in_cent"], name: "index_auction_bids_on_auction_activity_id_and_amount_in_cent", unique: true
    t.index ["auction_activity_id"], name: "index_auction_bids_on_auction_activity_id"
    t.index ["member_id"], name: "index_auction_bids_on_member_id"
    t.index ["user_id"], name: "index_auction_bids_on_user_id"
  end

  create_table "banner_clicks", force: :cascade do |t|
    t.date "date"
    t.string "url", limit: 2048
    t.integer "count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["url", "date"], name: "index_banner_clicks_on_url_and_date", unique: true
  end

  create_table "brand_translations", force: :cascade do |t|
    t.bigint "brand_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["brand_id"], name: "index_brand_translations_on_brand_id"
    t.index ["locale"], name: "index_brand_translations_on_locale"
  end

  create_table "brands", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "cover"
    t.integer "position", default: 999999, null: false
    t.boolean "aws_lambda_image_generated", default: false
  end

  create_table "categories", force: :cascade do |t|
    t.bigint "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 1
    t.integer "position", default: 0
    t.string "icon"
    t.string "bg_color"
    t.integer "display_length", default: 5
    t.string "filter_icon"
    t.boolean "can_create_invoice", default: true
    t.integer "sort_item_ids", default: [], array: true
    t.integer "item_position", default: 99999999
    t.boolean "need_age_verification", default: false
    t.boolean "show_on_web", default: false
    t.integer "goto_kind", default: 1, null: false
    t.text "search_keywords", comment: "搜索关键词, 用于提升搜索商品准确度"
    t.string "external_url"
    t.boolean "aws_lambda_image_generated", default: false
    t.boolean "ae_drop_shipper", default: false
    t.string "ae_drop_shipper_category_id"
    t.index ["ae_drop_shipper_category_id"], name: "index_categories_on_ae_drop_shipper_category_id"
    t.index ["parent_id"], name: "index_categories_on_parent_id"
  end

  create_table "category_translations", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["category_id"], name: "index_category_translations_on_category_id"
    t.index ["locale"], name: "index_category_translations_on_locale"
  end

  create_table "cities", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "province_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "kind", default: 1
    t.string "code"
    t.index ["province_id"], name: "index_cities_on_province_id"
  end

  create_table "comments", force: :cascade do |t|
    t.string "content"
    t.string "pictures", array: true
    t.string "commentable_type"
    t.integer "commentable_id"
    t.bigint "user_id"
    t.bigint "item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "images", default: [], array: true
    t.integer "status", default: 1
    t.datetime "deleted_at"
    t.boolean "is_top", default: false
    t.string "user_nickname"
    t.string "user_avatar"
    t.integer "stock_keeping_unit_id"
    t.string "properties_text"
    t.integer "parent_id"
    t.integer "likes_count", default: 0
    t.integer "stars", default: 5, comment: "星级评分， 默认5分"
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable_type_and_commentable_id"
    t.index ["deleted_at"], name: "index_comments_on_deleted_at"
    t.index ["item_id"], name: "index_comments_on_item_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "counties", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "city_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "kind", default: 1
    t.string "code"
    t.index ["city_id"], name: "index_counties_on_city_id"
  end

  create_table "coupon_auto_assignments", force: :cascade do |t|
    t.date "start_date"
    t.date "end_date"
    t.datetime "last_assigned_at"
    t.integer "assign_type", default: 0
    t.integer "assign_user_ids", default: [], array: true
    t.integer "coupon_template_ids", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
  end

  create_table "coupon_packages", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.integer "status", default: 1
    t.integer "user_kind", default: 1
    t.integer "coupon_template_ids", default: [], array: true
    t.string "cover"
    t.datetime "start_at", default: "-Infinity"
    t.datetime "end_at", default: "Infinity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "store_id"
    t.index ["store_id"], name: "index_coupon_packages_on_store_id"
  end

  create_table "coupon_packages_users", id: false, force: :cascade do |t|
    t.integer "coupon_package_id"
    t.integer "user_id"
    t.index ["coupon_package_id"], name: "index_coupon_packages_users_on_coupon_package_id"
    t.index ["user_id", "coupon_package_id"], name: "index_coupon_packages_users_on_user_id_and_coupon_package_id", unique: true
    t.index ["user_id"], name: "index_coupon_packages_users_on_user_id"
  end

  create_table "coupon_template_translations", force: :cascade do |t|
    t.bigint "coupon_template_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.index ["coupon_template_id"], name: "index_coupon_template_translations_on_coupon_template_id"
    t.index ["locale"], name: "index_coupon_template_translations_on_locale"
  end

  create_table "coupon_templates", force: :cascade do |t|
    t.string "desc", comment: "使用说明"
    t.integer "kind", default: 1
    t.integer "denominations_in_cent", comment: "面额（单位：分）"
    t.float "discount"
    t.integer "at_least_amount_in_cent", comment: "订单满减金额"
    t.boolean "need_at_least_amount", default: false, comment: "是否有门槛使用"
    t.integer "time_kind", default: 1, comment: "用券时间类型"
    t.integer "time_limit_in_day", default: 0, comment: " 领取后限时使用 0 表示无限"
    t.datetime "start_at", comment: "开始时间（可以开始使用优惠券）"
    t.datetime "end_at", comment: "结束时间（不能再使用优惠券）"
    t.string "details_image"
    t.string "expired_image"
    t.string "ticket_image"
    t.boolean "enabled", default: true, comment: "是否启用优惠券"
    t.string "remarks"
    t.string "code", comment: "优惠券码"
    t.integer "users_count", default: 0
    t.integer "orders_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "item_ids", default: [], array: true
    t.integer "user_kind"
    t.string "qrcode"
    t.integer "target_kind", default: 1
    t.bigint "store_id"
    t.integer "channel", default: 1
    t.integer "category_ids", default: [], array: true
    t.integer "coupons_count", default: 0
    t.integer "brand_ids", default: [], array: true
    t.integer "sub_category_ids", default: [], array: true
    t.boolean "is_aus_qrcode", default: false
    t.string "delivery_types", default: [], array: true
    t.string "payment_types", default: [], array: true
    t.integer "party", default: 1, comment: "发券方"
    t.integer "min_denominations_in_cent"
    t.integer "max_denominations_in_cent"
    t.boolean "display_in_item_detail", default: false
    t.integer "usage_kind"
    t.datetime "assign_start_at", comment: "领取开始时间"
    t.datetime "assign_end_at", comment: "领取结束时间"
    t.integer "assign_total_quantity", default: 0, comment: "可领取总数量"
    t.integer "custom_list_ids", default: [], array: true
    t.integer "max_random_reduction_count", default: 0, null: false
    t.integer "cost_accounting", comment: "成本核算, 1: 平台, 2: 板块"
    t.index ["store_id"], name: "index_coupon_templates_on_store_id"
  end

  create_table "coupons", force: :cascade do |t|
    t.string "title"
    t.string "desc"
    t.string "code"
    t.integer "kind", default: 1
    t.datetime "expired_at"
    t.datetime "start_at"
    t.json "preferences", default: {}
    t.integer "status", default: 1
    t.bigint "coupon_template_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "time_kind", default: 1
    t.integer "item_ids", default: [], array: true
    t.string "qrcode"
    t.integer "target_kind", default: 1
    t.bigint "store_id"
    t.integer "channel", default: 1
    t.datetime "assigned_at"
    t.datetime "used_at"
    t.integer "coupon_type", default: 1
    t.bigint "invitee_id"
    t.integer "category_ids", default: [], array: true
    t.integer "brand_ids", default: [], array: true
    t.integer "sub_category_ids", default: [], array: true
    t.boolean "is_aus_qrcode", default: false
    t.string "delivery_types", default: [], array: true
    t.string "payment_types", default: [], array: true
    t.integer "party", default: 1, comment: "发券方"
    t.integer "custom_list_ids", default: [], array: true
    t.index ["coupon_template_id", "status"], name: "index_coupons_on_coupon_template_id_and_status"
    t.index ["coupon_template_id"], name: "index_coupons_on_coupon_template_id"
    t.index ["invitee_id"], name: "index_coupons_on_invitee_id"
    t.index ["store_id"], name: "index_coupons_on_store_id"
    t.index ["user_id"], name: "index_coupons_on_user_id"
  end

  create_table "custom_list_items", force: :cascade do |t|
    t.integer "position"
    t.bigint "item_id"
    t.bigint "custom_list_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "store_id"
    t.index ["custom_list_id"], name: "index_custom_list_items_on_custom_list_id"
    t.index ["item_id", "custom_list_id"], name: "index_custom_list_items_on_item_id_and_custom_list_id", unique: true
    t.index ["item_id"], name: "index_custom_list_items_on_item_id"
    t.index ["store_id"], name: "index_custom_list_items_on_store_id"
  end

  create_table "custom_list_translations", force: :cascade do |t|
    t.bigint "custom_list_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.index ["custom_list_id"], name: "index_custom_list_translations_on_custom_list_id"
    t.index ["locale"], name: "index_custom_list_translations_on_locale"
  end

  create_table "custom_lists", force: :cascade do |t|
    t.string "remark"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "as_category", default: false
    t.integer "position", default: 0
    t.bigint "store_id"
    t.string "icon"
    t.string "bg_color", default: "#FEEDDC"
    t.boolean "show_discount_rate", default: false
    t.boolean "same_day_delivery", default: false
    t.boolean "items_shuffled", default: false
    t.integer "kind", default: 1, comment: "列表类型"
    t.integer "parent_category_id"
    t.boolean "ae_drop_shipper", default: false
    t.index ["parent_category_id"], name: "index_custom_lists_on_parent_category_id"
    t.index ["store_id"], name: "index_custom_lists_on_store_id"
  end

  create_table "custom_pages", force: :cascade do |t|
    t.string "name"
    t.string "en_name"
    t.string "qrcode_url"
    t.json "components", default: []
    t.boolean "default", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "store_id"
    t.boolean "is_aus_qrcode", default: false
    t.string "bg_color"
    t.bigint "creator_id"
    t.integer "collaborator_ids", default: [], array: true
    t.index ["creator_id"], name: "index_custom_pages_on_creator_id"
    t.index ["store_id"], name: "index_custom_pages_on_store_id"
  end

  create_table "cutoff_times", force: :cascade do |t|
    t.string "time_at", default: [], array: true
    t.bigint "item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "weekdays", default: [], array: true
    t.integer "deliver_after_n_days", default: 2, comment: "默认接单后2天发货"
    t.index ["item_id"], name: "index_cutoff_times_on_item_id"
  end

  create_table "delivery_areas", force: :cascade do |t|
    t.string "suburb"
    t.string "postal_code"
    t.float "latitude"
    t.float "longitude"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "au_suburb_id"
    t.bigint "delivery_time_id"
    t.bigint "same_day_delivery_time_id"
    t.index ["au_suburb_id"], name: "index_delivery_areas_on_au_suburb_id"
    t.index ["delivery_time_id"], name: "index_delivery_areas_on_delivery_time_id"
    t.index ["same_day_delivery_time_id"], name: "index_delivery_areas_on_same_day_delivery_time_id"
  end

  create_table "delivery_time_order_date_analyses", force: :cascade do |t|
    t.integer "delivery_time_id"
    t.date "delivery_date"
    t.integer "distinct_address_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_date", "delivery_time_id"], name: "delivery_time_order_on_delivery_date_and_delivery_time", unique: true
  end

  create_table "delivery_time_period_settings", force: :cascade do |t|
    t.bigint "delivery_time_period_id"
    t.string "prefer_time"
    t.integer "order_address_limit_every_day", default: 0, comment: "订单地址数上限，不受限于系统设置的地址数配送上限"
    t.integer "freight_in_cent", default: 0, comment: "运费，单位：分"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "delivery_time_id"
    t.index ["delivery_time_id"], name: "index_delivery_time_period_settings_on_delivery_time_id"
    t.index ["delivery_time_period_id"], name: "index_delivery_time_period_settings_on_delivery_time_period_id"
  end

  create_table "delivery_time_period_translations", force: :cascade do |t|
    t.bigint "delivery_time_period_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.index ["delivery_time_period_id"], name: "index_22a0ee9988abd378953035bab7fb8eb026926fa8"
    t.index ["locale"], name: "index_delivery_time_period_translations_on_locale"
  end

  create_table "delivery_time_periods", force: :cascade do |t|
    t.bigint "delivery_time_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_time_id"], name: "index_delivery_time_periods_on_delivery_time_id"
  end

  create_table "delivery_times", force: :cascade do |t|
    t.string "name", comment: "名称"
    t.string "weekdays", default: [], array: true
    t.string "time_period", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "limited_by_orders_limit_every_day", default: true
    t.integer "specific_orders_limit_every_day", default: 0, comment: "特定订单上限，不受限于系统设置的地址数配送上限"
    t.integer "specific_total_orders_limit_every_day", default: 0, comment: "特定订单上限，不受限于系统设置的订单配送上限"
  end

  create_table "event_form_records", force: :cascade do |t|
    t.bigint "user_id"
    t.string "event_slug"
    t.json "data", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "event_page_id"
    t.datetime "completed_at"
    t.index ["event_page_id"], name: "index_event_form_records_on_event_page_id"
    t.index ["event_slug"], name: "index_event_form_records_on_event_slug"
    t.index ["user_id"], name: "index_event_form_records_on_user_id"
  end

  create_table "event_pages", force: :cascade do |t|
    t.string "slug"
    t.string "name"
    t.integer "event_form_records_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "external_links", force: :cascade do |t|
    t.string "name"
    t.string "link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "external_mini_programs", force: :cascade do |t|
    t.string "name", null: false
    t.string "origin_id", null: false
    t.string "path", null: false
    t.string "app_id", null: false
    t.integer "env_version", default: 0, null: false, comment: "小程序版本：0 release 正式版, 1 develop 开发版, 2 trial 体验版"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "extra_orders_limits", force: :cascade do |t|
    t.integer "order_amount_in_cent", null: false
    t.date "delivery_date", null: false
    t.datetime "begin_at", null: false
    t.integer "extra_merchant_delivery_orders_limit", default: 0, null: false, comment: "额外地址数配送上限"
    t.bigint "store_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "extra_merchant_delivery_total_orders_limit", default: 0, comment: "额外订单配送上限"
    t.index ["store_id", "delivery_date"], name: "index_extra_orders_limits_on_store_id_and_delivery_date", unique: true
    t.index ["store_id"], name: "index_extra_orders_limits_on_store_id"
  end

  create_table "form_item_applications", force: :cascade do |t|
    t.bigint "form_item_id"
    t.bigint "user_id"
    t.bigint "store_id"
    t.integer "channel"
    t.hstore "apply_properties", comment: "申请信息"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["form_item_id"], name: "index_form_item_applications_on_form_item_id"
    t.index ["store_id"], name: "index_form_item_applications_on_store_id"
    t.index ["user_id"], name: "index_form_item_applications_on_user_id"
  end

  create_table "form_item_translations", force: :cascade do |t|
    t.bigint "form_item_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.text "description"
    t.string "name_placeholder", comment: "姓名占位符"
    t.string "mobile_placeholder", comment: "手机号占位符"
    t.string "email_placeholder", comment: "邮箱占位符"
    t.string "birthday_placeholder", comment: "生日占位符"
    t.string "address_placeholder", comment: "地址占位符"
    t.string "remark_placeholder", comment: "备注占位符"
    t.index ["form_item_id"], name: "index_form_item_translations_on_form_item_id"
    t.index ["locale"], name: "index_form_item_translations_on_locale"
  end

  create_table "form_items", force: :cascade do |t|
    t.integer "listing_type"
    t.bigint "category_id"
    t.integer "parent_category_id"
    t.integer "minor_category_id"
    t.string "cover"
    t.string "main_images", default: [], array: true
    t.string "detail_images", default: [], array: true
    t.string "form_options", default: [], array: true
    t.string "notification_emails", comment: "多个email用分号隔开"
    t.string "translated_searchable_title"
    t.string "translated_searchable_description"
    t.bigint "store_id"
    t.string "channels", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_form_items_on_category_id"
    t.index ["minor_category_id"], name: "index_form_items_on_minor_category_id"
    t.index ["parent_category_id"], name: "index_form_items_on_parent_category_id"
    t.index ["store_id"], name: "index_form_items_on_store_id"
  end

  create_table "freight_template_translations", force: :cascade do |t|
    t.bigint "freight_template_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["freight_template_id"], name: "index_freight_template_translations_on_freight_template_id"
    t.index ["locale"], name: "index_freight_template_translations_on_locale"
  end

  create_table "freight_templates", force: :cascade do |t|
    t.integer "first_kg_charge_in_cent", null: false, comment: "1KG以内运费"
    t.integer "second_kg_charge_in_cent", null: false, comment: "2KG以内运费"
    t.integer "continued_weight_charge_in_cent", null: false, comment: "超过2KG后每KG运费，不足1KG按1KG算"
    t.integer "extra_charge_in_cent", default: 0, null: false, comment: "超过2KG后一次性的额外费用"
    t.string "type", null: false
    t.bigint "freight_template_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "delivery_type", default: 1
    t.integer "free_shipping_amount_in_cent", comment: "满金额免运费"
    t.integer "first_kg_cost_in_cent", default: 0, comment: "1KG以内运费成本"
    t.integer "second_kg_cost_in_cent", default: 0, comment: "2KG以内运费成本"
    t.integer "continued_weight_cost_in_cent", default: 0, comment: "超过2KG后每KG运费成本，不足1KG按1KG算"
    t.integer "extra_cost_in_cent", default: 0, comment: "超过2KG后一次性的额外费用"
    t.bigint "store_id"
    t.integer "app_free_shipping_amount_in_cent", comment: "App满金额免运费"
    t.integer "web_free_shipping_amount_in_cent", comment: "Web满金额免运费"
    t.integer "mini_program_free_shipping_amount_in_cent", comment: "小程序满金额免运费"
    t.boolean "ae_drop_shipper", default: false
    t.integer "long_distance_fee_in_cent", default: 0, comment: "远程运费"
    t.index ["freight_template_id"], name: "index_freight_templates_on_freight_template_id"
    t.index ["store_id"], name: "index_freight_templates_on_store_id"
  end

  create_table "freight_templates_items", id: false, force: :cascade do |t|
    t.bigint "freight_template_id"
    t.bigint "item_id"
    t.index ["freight_template_id"], name: "index_freight_templates_items_on_freight_template_id"
    t.index ["item_id"], name: "index_freight_templates_items_on_item_id"
  end

  create_table "gift_activities", force: :cascade do |t|
    t.datetime "start_at"
    t.datetime "end_at"
    t.integer "status", default: 1
    t.json "rules"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "store_id"
    t.index ["store_id"], name: "index_gift_activities_on_store_id"
  end

  create_table "gift_card_coupons", force: :cascade do |t|
    t.bigint "gift_card_template_id"
    t.string "code"
    t.integer "denominations_in_cent", default: 0
    t.integer "used_amount_in_cent", default: 0
    t.integer "status", default: 1
    t.datetime "expired_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "pin_code"
    t.integer "store_ids", default: [], array: true
    t.boolean "not_eligible_for_free_gift", default: true, comment: "是否不参与满赠, 默认不参与"
    t.index ["gift_card_template_id"], name: "index_gift_card_coupons_on_gift_card_template_id"
  end

  create_table "gift_card_templates", force: :cascade do |t|
    t.integer "denominations_in_cent", default: 0
    t.integer "quantity", default: 0
    t.datetime "expired_at"
    t.string "purchaser"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "store_ids", default: [], array: true
    t.integer "purpose", default: 1
    t.boolean "not_eligible_for_free_gift", default: true, comment: "是否不参与满赠, 默认不参与"
  end

  create_table "groupon_activities", force: :cascade do |t|
    t.integer "kind"
    t.integer "price_in_cent", comment: "产品拼团价格"
    t.integer "user_count", comment: "拼团要求人数"
    t.datetime "start_at"
    t.datetime "end_at"
    t.boolean "enabled"
    t.bigint "item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "store_id"
    t.boolean "is_real", default: false
    t.integer "expired_hours", default: 0
    t.string "type", default: "MagicBean::NormalGrouponActivity"
    t.integer "wms_sync_type", default: 1
    t.text "rules"
    t.index ["item_id"], name: "index_groupon_activities_on_item_id"
    t.index ["store_id"], name: "index_groupon_activities_on_store_id"
  end

  create_table "groupons", force: :cascade do |t|
    t.integer "status"
    t.datetime "expired_at"
    t.datetime "finished_at"
    t.datetime "cancel_at"
    t.bigint "creator_id"
    t.bigint "groupon_activity_id"
    t.bigint "sku_groupon_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "channel", default: 1
    t.bigint "store_id"
    t.index ["creator_id"], name: "index_groupons_on_creator_id"
    t.index ["groupon_activity_id"], name: "index_groupons_on_groupon_activity_id"
    t.index ["sku_groupon_id"], name: "index_groupons_on_sku_groupon_id"
    t.index ["store_id"], name: "index_groupons_on_store_id"
  end

  create_table "histories", force: :cascade do |t|
    t.string "operator_type"
    t.bigint "operator_id"
    t.string "operatable_type"
    t.bigint "operatable_id"
    t.integer "action_type", null: false
    t.jsonb "params"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "page_type", default: 1
    t.integer "channel", default: 1
    t.bigint "store_id"
    t.index ["action_type"], name: "index_histories_on_action_type"
    t.index ["operatable_type", "action_type", "store_id"], name: "index_histories_on_operatable_type_and_action_type_and_store_id"
    t.index ["operatable_type", "action_type"], name: "index_histories_on_operatable_type_and_action_type"
    t.index ["operatable_type", "operatable_id"], name: "index_histories_on_operatable_type_and_operatable_id"
    t.index ["operator_type", "operator_id"], name: "index_histories_on_operator_type_and_operator_id"
    t.index ["store_id"], name: "index_histories_on_store_id"
  end

  create_table "homepage_paging_settings", force: :cascade do |t|
    t.string "name"
    t.string "image"
    t.bigint "custom_page_id"
    t.integer "position", default: 99
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "show_banners", default: true
    t.jsonb "banners", default: {}
    t.boolean "show_image_notice", default: true
    t.jsonb "image_notice", default: {}
    t.string "background_image"
    t.bigint "store_id"
    t.string "selected_image", comment: "选中图片"
    t.index ["custom_page_id"], name: "index_homepage_paging_settings_on_custom_page_id"
    t.index ["store_id"], name: "index_homepage_paging_settings_on_store_id"
  end

  create_table "hot_search_translations", force: :cascade do |t|
    t.bigint "hot_search_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "word"
    t.index ["hot_search_id"], name: "index_hot_search_translations_on_hot_search_id"
    t.index ["locale"], name: "index_hot_search_translations_on_locale"
  end

  create_table "hot_searches", force: :cascade do |t|
    t.integer "position", null: false
    t.bigint "store_id"
    t.boolean "show", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "channels", default: []
    t.boolean "ae_drop_shipper", default: false
    t.index ["store_id"], name: "index_hot_searches_on_store_id"
  end

  create_table "hot_sell_configs", force: :cascade do |t|
    t.integer "last_x_days", default: 14, comment: "过去X天销量"
    t.integer "show_item_nums", default: 30, comment: "最多展示几个商品"
    t.boolean "contains_order_gift", default: true, comment: "销量包含全场满赠数量"
    t.boolean "contains_order_pool_gift", default: true, comment: "销量包含优惠池满赠数量"
    t.boolean "is_show_storage_on_sale", default: true, comment: "仅展示有库存开卖商品"
    t.boolean "enabled", default: true, comment: "是否展示热卖榜"
    t.bigint "category_id"
    t.bigint "store_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position", default: 0
    t.index ["category_id"], name: "index_hot_sell_configs_on_category_id"
    t.index ["store_id"], name: "index_hot_sell_configs_on_store_id"
  end

  create_table "integral_records", force: :cascade do |t|
    t.integer "available_integral"
    t.integer "blocked_integral"
    t.integer "integral"
    t.integer "kind"
    t.bigint "member_id"
    t.string "targetable_type"
    t.bigint "targetable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 2
    t.integer "channel", default: 1
    t.index ["member_id"], name: "index_integral_records_on_member_id"
    t.index ["targetable_type", "targetable_id"], name: "index_integral_records_on_targetable_type_and_targetable_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.string "title"
    t.string "abn"
    t.string "first_name"
    t.string "last_name"
    t.string "tel_number"
    t.string "address"
    t.string "email"
    t.bigint "user_id"
    t.string "alias_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_default", default: false
    t.integer "kind", default: 1
    t.index ["user_id"], name: "index_invoices_on_user_id"
  end

  create_table "item_banner_clicks", force: :cascade do |t|
    t.date "date"
    t.integer "count", default: 0
    t.bigint "item_banner_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_banner_id", "date"], name: "index_item_banner_clicks_on_item_banner_id_and_date", unique: true
    t.index ["item_banner_id"], name: "index_item_banner_clicks_on_item_banner_id"
  end

  create_table "item_banners", force: :cascade do |t|
    t.string "title"
    t.string "banner"
    t.integer "item_ids", default: [], array: true
    t.datetime "start_at"
    t.datetime "end_at"
    t.string "path", comment: "跳转路径"
    t.boolean "enabled", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "item_nutrition_values", force: :cascade do |t|
    t.bigint "item_id"
    t.bigint "nutrition_id"
    t.string "avg_qty_per_package"
    t.string "avg_qty_per_100_units"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_item_nutrition_values_on_item_id"
    t.index ["nutrition_id"], name: "index_item_nutrition_values_on_nutrition_id"
  end

  create_table "item_search_histories", force: :cascade do |t|
    t.string "word"
    t.date "search_date"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "channel", default: 2, comment: "渠道, 默认app"
    t.index ["user_id"], name: "index_item_search_histories_on_user_id"
  end

  create_table "item_tag_group_translations", force: :cascade do |t|
    t.bigint "item_tag_group_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["item_tag_group_id"], name: "index_item_tag_group_translations_on_item_tag_group_id"
    t.index ["locale"], name: "index_item_tag_group_translations_on_locale"
  end

  create_table "item_tag_groups", force: :cascade do |t|
    t.bigint "item_tag_type_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_tag_type_id"], name: "index_item_tag_groups_on_item_tag_type_id"
  end

  create_table "item_tag_relations", force: :cascade do |t|
    t.bigint "item_id"
    t.bigint "item_tag_id"
    t.boolean "allow_view_same_tag_items", default: false, comment: "是否允许查看同标签下的商品"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["allow_view_same_tag_items"], name: "index_item_tag_relations_on_allow_view_same_tag_items"
    t.index ["item_id"], name: "index_item_tag_relations_on_item_id"
    t.index ["item_tag_id"], name: "index_item_tag_relations_on_item_tag_id"
  end

  create_table "item_tag_translations", force: :cascade do |t|
    t.bigint "item_tag_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["item_tag_id"], name: "index_item_tag_translations_on_item_tag_id"
    t.index ["locale"], name: "index_item_tag_translations_on_locale"
  end

  create_table "item_tag_types", force: :cascade do |t|
    t.string "name", comment: "类型名称"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "item_tags", force: :cascade do |t|
    t.bigint "item_tag_group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "item_tag_relations_count", default: 0, comment: "打标签次数"
    t.index ["item_tag_group_id"], name: "index_item_tags_on_item_tag_group_id"
  end

  create_table "item_translations", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.text "description"
    t.string "shared_description"
    t.index ["item_id"], name: "index_item_translations_on_item_id"
    t.index ["locale"], name: "index_item_translations_on_locale"
  end

  create_table "items", force: :cascade do |t|
    t.integer "buy_quota", default: 0, comment: "每个买家帐号累计限购多少件, 0表示无限制"
    t.string "no", comment: "商品货号（为商品设置的外部编号）"
    t.integer "price_in_cent", default: 0
    t.integer "item_type", default: 1
    t.integer "quantity", default: 0, null: false, comment: "总库存量"
    t.integer "listing_type", default: 1
    t.datetime "start_selling_at"
    t.integer "comments_count", default: 0
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "main_images", default: [], array: true
    t.string "detail_images", default: [], array: true
    t.integer "likes_count", default: 0
    t.integer "likes_count_offset", default: 0, null: false
    t.integer "sales_count", default: 0
    t.integer "fixed_freight", default: 0, comment: "统一运费"
    t.integer "freight_type", default: 1, null: false
    t.bigint "qa_and_guarantee_id"
    t.bigint "brand_id"
    t.integer "monthly_sales_count_offset", default: 0, null: false
    t.integer "actual_monthly_sales_count", default: 0, null: false
    t.string "qrcode"
    t.string "sub_title"
    t.string "cover"
    t.string "share_cover"
    t.integer "position", default: 99999999
    t.string "delivery_type", default: [], array: true
    t.integer "strikethrough_price_in_cent"
    t.integer "buy_quota_days", default: 0
    t.string "detail_video"
    t.integer "fixed_freight_cost", default: 0, comment: "固定运费成本"
    t.bigint "store_id"
    t.bigint "product_id"
    t.integer "sales_count_offset", default: 0
    t.integer "display_sales_count", default: 0
    t.integer "minor_category_id"
    t.boolean "is_presell", default: false
    t.date "presell_dispatch_on"
    t.datetime "presell_end_at"
    t.date "latest_presell_dispatch_on"
    t.string "short_title"
    t.integer "parent_category_id"
    t.string "top_left_corner_tag_image"
    t.boolean "is_virtual", default: false
    t.boolean "is_aus_qrcode", default: false
    t.boolean "coupon_enabled", default: true
    t.string "translated_searchable_title"
    t.string "translated_searchable_description"
    t.boolean "free_shipping", default: true, comment: "是否参与包邮计划"
    t.integer "storage_method", default: 0
    t.string "production_place", comment: "产地"
    t.string "allergen", comment: "过敏原"
    t.string "serving_per_package", comment: "本包装包含份数"
    t.string "serving_size", comment: "每一份的份量"
    t.integer "new_user_price_in_cent"
    t.string "ingredient"
    t.string "delivery_weekdays", default: [], array: true
    t.boolean "gift_card_enabled", default: true
    t.string "channels", default: [], array: true
    t.date "expiration_date", comment: "产品过期日期"
    t.boolean "show_expiration_date", default: false
    t.integer "days_ahead_to_show_expiration"
    t.integer "web_category_id"
    t.integer "parent_web_category_id"
    t.integer "minor_web_category_id"
    t.date "batch_reindex_date", comment: "每晚批量同步ES日期"
    t.boolean "not_eligible_for_free_gift", default: false, comment: "商品是否不参与满赠"
    t.datetime "first_sale_at", comment: "首次上架开卖时间"
    t.string "leader", default: "其他", comment: "负责人"
    t.boolean "gift_only", default: false, comment: "只用作赠品，无法单独加购或直接购买"
    t.datetime "deleted_at", comment: "软删除时间"
    t.string "ae_category_id"
    t.jsonb "ae_product_attributes"
    t.jsonb "ae_freight_info", comment: "AE物流信息"
    t.boolean "aws_lambda_image_generated", default: false
    t.boolean "ae_drop_shipper", default: false
    t.text "ae_h5_description"
    t.boolean "is_seasonal", default: false
    t.boolean "is_fresh_daily", default: false
    t.boolean "is_ae_choice", comment: "是否是AE官方产品"
    t.string "ae_delivery_date_desc", comment: "AE发货时间描述, 例: Oct. 31 - Nov. 07"
    t.string "ae_delivery_date", comment: "AE发货日期，AE产品的发货日期由AE计算"
    t.integer "ae_estimated_delivery_days", comment: "AE预估发货天数"
    t.boolean "ae_unsaleable", default: false, comment: "AE端是否不可销售"
    t.integer "hot_sell_ranking"
    t.datetime "last_sale_at", comment: "最近一次开卖时间"
    t.datetime "last_offline_at", comment: "最近一次下架时间"
    t.bigint "hot_sell_config_id"
    t.integer "expiration_reminder_before_n_days", comment: "提前n天提示过期日期弹窗"
    t.integer "ae_free_shipping_threshold_in_cent", default: 0, comment: "AE 免运费门槛"
    t.date "ae_shipping_info_last_updated_date", comment: "AE商品物流信息最后更新日期"
    t.date "ae_basic_info_last_updated_date", comment: "AE商品基础信息最后更新日期"
    t.index ["ae_drop_shipper"], name: "index_items_on_ae_drop_shipper"
    t.index ["brand_id"], name: "index_items_on_brand_id"
    t.index ["category_id"], name: "index_items_on_category_id"
    t.index ["hot_sell_config_id"], name: "index_items_on_hot_sell_config_id"
    t.index ["minor_category_id"], name: "index_items_on_minor_category_id"
    t.index ["minor_web_category_id"], name: "index_items_on_minor_web_category_id"
    t.index ["parent_category_id"], name: "index_items_on_parent_category_id"
    t.index ["parent_web_category_id"], name: "index_items_on_parent_web_category_id"
    t.index ["product_id"], name: "index_items_on_product_id"
    t.index ["qa_and_guarantee_id"], name: "index_items_on_qa_and_guarantee_id"
    t.index ["quantity"], name: "index_items_on_quantity"
    t.index ["store_id", "parent_category_id", "category_id"], name: "index_items_on_store_id_and_parent_category_id_and_category_id"
    t.index ["store_id"], name: "index_items_on_store_id"
    t.index ["web_category_id"], name: "index_items_on_web_category_id"
  end

  create_table "kuaidi_company_mappings", force: :cascade do |t|
    t.string "cn_name", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cn_name"], name: "index_kuaidi_company_mappings_on_cn_name", unique: true
  end

  create_table "live_comments", force: :cascade do |t|
    t.bigint "live_room_id"
    t.bigint "user_id"
    t.string "nickname"
    t.string "device_id"
    t.string "user_ip"
    t.text "content"
    t.datetime "commented_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["live_room_id"], name: "index_live_comments_on_live_room_id"
    t.index ["user_id"], name: "index_live_comments_on_user_id"
  end

  create_table "live_room_lotteries", force: :cascade do |t|
    t.string "name", null: false
    t.integer "luck_limit", default: 0, null: false
    t.integer "duration_in_minutes", null: false
    t.integer "state", default: 0, null: false
    t.datetime "started_at"
    t.integer "participators_count", default: 0, null: false
    t.string "award_cover", null: false
    t.string "remark"
    t.bigint "live_room_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "draw_method", default: 0, null: false
    t.index ["live_room_id"], name: "index_live_room_lotteries_on_live_room_id"
  end

  create_table "live_room_lottery_winning_users", force: :cascade do |t|
    t.bigint "live_room_lottery_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "address_id"
    t.hstore "receiver_properties"
    t.bigint "live_room_id"
    t.index ["live_room_id"], name: "index_live_room_lottery_winning_users_on_live_room_id"
    t.index ["live_room_lottery_id", "user_id"], name: "index_lottery_winning_users_on_lottery_id_and_user_id", unique: true
    t.index ["live_room_lottery_id"], name: "index_live_room_lottery_winning_users_on_live_room_lottery_id"
    t.index ["user_id"], name: "index_live_room_lottery_winning_users_on_user_id"
  end

  create_table "live_room_orders", force: :cascade do |t|
    t.bigint "live_room_id"
    t.bigint "order_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["live_room_id"], name: "index_live_room_orders_on_live_room_id"
    t.index ["order_id"], name: "index_live_room_orders_on_order_id"
    t.index ["user_id"], name: "index_live_room_orders_on_user_id"
  end

  create_table "live_room_skus", force: :cascade do |t|
    t.bigint "live_room_id"
    t.bigint "stock_keeping_unit_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["live_room_id"], name: "index_live_room_skus_on_live_room_id"
    t.index ["stock_keeping_unit_id"], name: "index_live_room_skus_on_stock_keeping_unit_id"
  end

  create_table "live_room_subscriptions", force: :cascade do |t|
    t.bigint "live_room_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["live_room_id"], name: "index_live_room_subscriptions_on_live_room_id"
    t.index ["user_id"], name: "index_live_room_subscriptions_on_user_id"
  end

  create_table "live_room_viewed_user_stats", force: :cascade do |t|
    t.integer "count", default: 0, null: false
    t.string "time_str", comment: "精确到分钟的时间"
    t.bigint "live_room_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["live_room_id"], name: "index_live_room_viewed_user_stats_on_live_room_id"
    t.index ["time_str"], name: "index_live_room_viewed_user_stats_on_time_str"
  end

  create_table "live_room_viewed_users", force: :cascade do |t|
    t.bigint "live_room_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["live_room_id", "user_id"], name: "index_live_room_viewed_users_on_live_room_id_and_user_id", unique: true
    t.index ["live_room_id"], name: "index_live_room_viewed_users_on_live_room_id"
    t.index ["user_id"], name: "index_live_room_viewed_users_on_user_id"
  end

  create_table "live_rooms", force: :cascade do |t|
    t.string "title", null: false
    t.bigint "host_id", null: false
    t.string "host_nickname", null: false
    t.datetime "start_at", null: false
    t.bigint "admin_user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "app_push_protocol", default: 1, null: false
    t.integer "app_pull_protocol", default: 0, null: false
    t.bigint "store_id"
    t.integer "actual_viewed_count", default: 0, comment: "实际观看次数"
    t.integer "viewed_count_offset", default: 0, comment: "基础观看次数"
    t.integer "viewed_count_multiplier", default: 1, comment: "实际观看次数乘数"
    t.integer "actual_liked_count", default: 0, comment: "实际点赞次数"
    t.integer "liked_count_offset", default: 0, comment: "基础点赞次数"
    t.integer "liked_count_multiplier", default: 1, comment: "实际点赞次数乘数"
    t.integer "actual_peak_concurrent_users_count", default: 0, comment: "实际峰值在线人数"
    t.integer "actual_viewed_users_count", default: 0, comment: "实际观看人数"
    t.integer "actual_liked_users_count", default: 0, comment: "实际点赞人数"
    t.integer "average_user_viewed_time_in_sec", default: 0, comment: "平均观看时长"
    t.integer "state", default: 0
    t.datetime "finished_at"
    t.datetime "live_at"
    t.integer "actual_comments_count", default: 0, comment: "实际评论数"
    t.integer "actual_comment_users_count", default: 0, comment: "实际评论人数"
    t.bigint "coupon_package_id"
    t.string "bg_img"
    t.string "bg_color"
    t.integer "live_room_subscriptions_count", default: 0
    t.string "announcement"
    t.bigint "highlighted_sku_id"
    t.string "subscription_noti_title"
    t.string "subscription_noti_body"
    t.string "custom_page_icon"
    t.bigint "custom_page_id"
    t.bigint "current_lottery_id"
    t.string "share_icon"
    t.integer "subscription_count_offset", default: 0, comment: "订阅基础数"
    t.integer "subscription_count_multiplier", default: 0, comment: "订阅数乘数"
    t.integer "lottery_win_limits", default: 0, comment: "中奖次数上限，0 表示不限制"
    t.integer "orientation", default: 0, null: false
    t.string "agora_vod_filename"
    t.string "agora_mp4_filenames", default: [], array: true
    t.index ["admin_user_id"], name: "index_live_rooms_on_admin_user_id"
    t.index ["coupon_package_id"], name: "index_live_rooms_on_coupon_package_id"
    t.index ["current_lottery_id"], name: "index_live_rooms_on_current_lottery_id"
    t.index ["custom_page_id"], name: "index_live_rooms_on_custom_page_id"
    t.index ["highlighted_sku_id"], name: "index_live_rooms_on_highlighted_sku_id"
    t.index ["host_id"], name: "index_live_rooms_on_host_id"
    t.index ["store_id"], name: "index_live_rooms_on_store_id"
  end

  create_table "logistics", force: :cascade do |t|
    t.string "no"
    t.string "company"
    t.jsonb "traces"
    t.string "remark", comment: "备注(用于多个物流单时备注该物流单包含的商品)"
    t.bigint "order_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "shipment_no", comment: "erp发货单号"
    t.integer "sku_ids", default: [], array: true
    t.boolean "is_delivered", default: false
    t.string "ae_order_no", comment: "AE 订单号"
    t.index ["no"], name: "index_logistics_on_no"
    t.index ["order_id"], name: "index_logistics_on_order_id"
  end

  create_table "marketing_messages", force: :cascade do |t|
    t.string "content"
    t.bigint "store_id"
    t.bigint "admin_user_id"
    t.integer "state", default: 1, comment: "draft: 0, pending: 1, pushed: 2"
    t.integer "user_ids", default: [], comment: "指定用户", array: true
    t.datetime "push_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sms_platform", default: "aws", comment: "短信发送平台"
    t.integer "manual_user_ids", default: [], comment: "手动添加用户", array: true
    t.index ["admin_user_id"], name: "index_marketing_messages_on_admin_user_id"
    t.index ["store_id"], name: "index_marketing_messages_on_store_id"
  end

  create_table "members", force: :cascade do |t|
    t.string "mobile"
    t.date "birthday"
    t.integer "available_integral", default: 0, comment: "可用积分"
    t.integer "blocked_integral", default: 0, comment: "冻结积分"
    t.integer "cumulative_integral", default: 0, comment: "累积获取积分"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "inviter_id"
    t.string "invite_code"
    t.boolean "assigned_app_newbie_coupon", default: false
    t.integer "app_available_integral", default: 0, comment: "APP 可用积分"
    t.integer "app_blocked_integral", default: 0, comment: "APP 冻结积分"
    t.integer "app_cumulative_integral", default: 0, comment: "APP 累积获取积分"
    t.integer "channel", default: 0
    t.string "email"
    t.boolean "receive_activity_email", default: false
    t.boolean "can_edit_birthday", default: true
    t.datetime "email_verified_at"
    t.string "first_name"
    t.string "last_name"
    t.string "email_confirmation_token"
    t.index ["email"], name: "index_members_on_email"
    t.index ["email_confirmation_token"], name: "index_members_on_email_confirmation_token", unique: true
    t.index ["invite_code"], name: "index_members_on_invite_code", unique: true
    t.index ["inviter_id"], name: "index_members_on_inviter_id"
    t.index ["mobile"], name: "index_members_on_mobile", unique: true
    t.index ["user_id"], name: "index_members_on_user_id"
  end

  create_table "message_unread_counters", force: :cascade do |t|
    t.bigint "user_id"
    t.integer "order_tracking_count", default: 0, null: false, comment: "订单追踪未读消息数"
    t.integer "customer_service_count", default: 0, null: false, comment: "客服通知未读消息数"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sku_in_stock_count", default: 0
    t.index ["user_id"], name: "index_message_unread_counters_on_user_id"
  end

  create_table "mine_page_activity_setting_translations", force: :cascade do |t|
    t.bigint "mine_page_activity_setting_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["locale"], name: "index_mine_page_activity_setting_translations_on_locale"
    t.index ["mine_page_activity_setting_id"], name: "index_48c11252bac7e9d1a2567836f8d2abe135a5d43e"
  end

  create_table "mine_page_activity_settings", force: :cascade do |t|
    t.string "icon", comment: "活动图标"
    t.bigint "custom_page_id"
    t.bigint "store_id"
    t.integer "position", default: 999, comment: "排序"
    t.boolean "enabled", default: true, comment: "是否启用"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "path", comment: "跳转页面路径"
    t.index ["custom_page_id"], name: "index_mine_page_activity_settings_on_custom_page_id"
    t.index ["store_id"], name: "index_mine_page_activity_settings_on_store_id"
  end

  create_table "mobile_blacklists", force: :cascade do |t|
    t.bigint "user_id"
    t.string "mobile", null: false
    t.boolean "enabled", default: true, null: false
    t.boolean "live_comment_disabled", default: true, null: false
    t.boolean "live_lottery_disabled", default: true, null: false
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "order_disabled", default: true
    t.boolean "push_notification_disabled", default: false, comment: "不可接收推送通知"
    t.boolean "marketing_sms_disabled", default: false, comment: "不可接收营销短信"
    t.index ["mobile"], name: "index_mobile_blacklists_on_mobile", unique: true
    t.index ["user_id"], name: "index_mobile_blacklists_on_user_id"
  end

  create_table "multi_lang_config_translations", force: :cascade do |t|
    t.bigint "multi_lang_config_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.index ["locale"], name: "index_multi_lang_config_translations_on_locale"
    t.index ["multi_lang_config_id"], name: "index_multi_lang_config_translations_on_multi_lang_config_id"
  end

  create_table "multi_lang_configs", force: :cascade do |t|
    t.string "key", null: false
    t.string "name", null: false
    t.integer "kind", default: 0
    t.bigint "store_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "hint"
    t.index ["store_id"], name: "index_multi_lang_configs_on_store_id"
  end

  create_table "nutrition_translations", force: :cascade do |t|
    t.bigint "nutrition_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["locale"], name: "index_nutrition_translations_on_locale"
    t.index ["nutrition_id"], name: "index_nutrition_translations_on_nutrition_id"
  end

  create_table "nutritions", force: :cascade do |t|
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_nutritions_on_slug", unique: true
  end

  create_table "operation_records", force: :cascade do |t|
    t.bigint "admin_user_id"
    t.string "operatable_type"
    t.bigint "operatable_id"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.bigint "store_id"
    t.integer "channel", default: 1
    t.index ["admin_user_id"], name: "index_operation_records_on_admin_user_id"
    t.index ["operatable_type", "operatable_id"], name: "index_operation_records_on_operatable_type_and_operatable_id"
    t.index ["store_id"], name: "index_operation_records_on_store_id"
  end

  create_table "order_date_analyses", force: :cascade do |t|
    t.date "delivery_date"
    t.integer "store_id"
    t.integer "distinct_address_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_date", "store_id"], name: "index_order_date_analyses_on_delivery_date_and_store_id", unique: true
  end

  create_table "order_invoices", force: :cascade do |t|
    t.string "no"
    t.bigint "order_id"
    t.integer "state", default: 0
    t.hstore "invoice_properties"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["no"], name: "index_order_invoices_on_no", unique: true
    t.index ["order_id"], name: "index_order_invoices_on_order_id", unique: true
  end

  create_table "order_items", force: :cascade do |t|
    t.integer "quantity", default: 0
    t.integer "amount_in_cent", default: 0, comment: "订单项总价"
    t.integer "price_in_cent", default: 0, comment: "订单项单价"
    t.bigint "stock_keeping_unit_id"
    t.bigint "order_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "properties_text"
    t.string "title"
    t.string "image"
    t.integer "item_id"
    t.integer "weight_in_gram", default: 0, null: false
    t.json "groups", default: []
    t.integer "sku_type", default: 1
    t.integer "real_price_in_cent"
    t.bigint "store_id"
    t.integer "display_price_in_cent", default: 0
    t.bigint "promo_code_id"
    t.integer "gst_percent", default: 0
    t.decimal "gst_amount_in_cent", precision: 12, scale: 2, default: "0.0"
    t.integer "marketing_mode", default: 1
    t.string "short_title"
    t.integer "source_page_name"
    t.integer "source_channel"
    t.integer "source_custom_list_id"
    t.json "source_extra_hash"
    t.integer "pool_price_in_cent"
    t.integer "strikethrough_price_in_cent"
    t.integer "strikethrough_amount_in_cent"
    t.boolean "is_new_user_price", default: false
    t.boolean "live_top", default: false
    t.integer "service_amount_in_cent", default: 0, comment: "均摊手续费($)"
    t.integer "cost_integral", default: 0, comment: "均摊金币数量"
    t.integer "gift_card_amount_in_cent", default: 0, comment: "均摊礼品卡($)"
    t.integer "real_amount_in_cent", default: 0, comment: "最终的优惠金额"
    t.boolean "not_eligible_for_free_gift", default: false, comment: "商品是否不参与满赠"
    t.integer "ae_gst_amount_in_cent", default: 0
    t.boolean "is_box_regulation", default: false
    t.index ["item_id"], name: "index_order_items_on_item_id"
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["promo_code_id"], name: "index_order_items_on_promo_code_id"
    t.index ["source_custom_list_id"], name: "index_order_items_on_source_custom_list_id"
    t.index ["stock_keeping_unit_id"], name: "index_order_items_on_stock_keeping_unit_id"
    t.index ["store_id"], name: "index_order_items_on_store_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "no"
    t.integer "payment_in_cent", default: 0
    t.integer "status", default: 1
    t.integer "amount_in_cent", default: 0
    t.datetime "paid_at"
    t.hstore "receiver_properties", comment: "收件人信息"
    t.string "transaction_id", comment: "外部支付单号"
    t.datetime "finished_at", comment: "订单完成时间，通过计算判断是否可售后"
    t.string "buyer_message"
    t.string "refund_no"
    t.string "prepay_id"
    t.string "cancel_reason"
    t.integer "actually_amount_in_cent", default: 0, comment: "订单实际金额，去除部分退款之后实际金额"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "quantity", default: 0
    t.datetime "delivered_at"
    t.datetime "confirmed_at"
    t.text "remark", comment: "卖家备注"
    t.bigint "province_id"
    t.integer "freight_in_cent", default: 0, null: false
    t.integer "after_sales_count", default: 0
    t.integer "total_payment_in_cent", default: 0, null: false
    t.bigint "coupon_id"
    t.integer "original_payment_in_cent"
    t.bigint "groupon_activity_id"
    t.bigint "sku_groupon_id"
    t.string "type"
    t.bigint "groupon_id"
    t.boolean "is_sent_but_status_not_show", default: false
    t.string "apply_reason"
    t.string "scene_code"
    t.bigint "gift_activity_id"
    t.json "gifts_properties"
    t.integer "cost_integral", default: 0
    t.bigint "self_pick_up_id"
    t.integer "delivery_type", default: 1
    t.integer "sync_status", default: 1, comment: "同步到 wms 状态"
    t.datetime "synced_at"
    t.float "wechat_service_percentage", default: 0.0
    t.float "credit_card_service_percentage", default: 0.0
    t.integer "wechat_payment_in_cent", default: 0
    t.integer "credit_card_payment_in_cent", default: 0
    t.decimal "aud_to_cny_exchange_rate", precision: 12, scale: 4, default: "0.0"
    t.string "delivery_date", comment: "配送日期"
    t.string "prefer_time", comment: "配送时间段"
    t.boolean "authority_to_leave", default: false
    t.integer "channel", default: 1
    t.integer "omipay_payment_dollar_in_cent", default: 0
    t.integer "omipay_service_amount_dollar_in_cent", default: 0
    t.integer "omipay_payment_in_cent", default: 0
    t.integer "original_freight_in_cent"
    t.integer "final_amount_in_cent"
    t.integer "freight_cost_in_cent", default: 0, comment: "订单运费成本"
    t.string "freight_remark", comment: "订单运费备注"
    t.string "payment_type"
    t.bigint "store_id"
    t.integer "integral_received_from_one_yuan", default: 0
    t.integer "integral_deducted_from_one_yuan", default: 0
    t.string "omipay_transaction_id"
    t.bigint "gift_card_coupon_id"
    t.integer "gift_card_amount_in_cent", default: 0
    t.string "omipay_platform"
    t.string "delivery_track"
    t.integer "gift_coupon_template_id"
    t.bigint "promo_code_id"
    t.boolean "mark_for_orders_limit", default: true, comment: "是否计算入每日上限订单数"
    t.integer "delivery_time_id"
    t.boolean "next_day_delivery", default: false
    t.datetime "deleted_by_user_at"
    t.integer "try_payment_times", comment: "用户尝试支付次数（只记信用卡支付）"
    t.integer "pool_coupon_template_ids", array: true
    t.json "pool_gifts_properties"
    t.json "active_pools", default: {}
    t.boolean "payment_in_progress", default: false
    t.integer "strikethrough_amount_in_cent"
    t.boolean "order_finished_reward_integral", default: true
    t.bigint "same_day_delivery_time_id"
    t.bigint "same_day_delivery_time_period_id"
    t.boolean "live_top", default: false
    t.boolean "deliver_to_door", default: false
    t.integer "supay_payment_dollar_in_cent", default: 0, comment: "Supay支付金额，单位：AUD"
    t.integer "supay_payment_in_cent", default: 0, comment: "Supay支付金额，单位：CNY"
    t.integer "supay_service_amount_dollar_in_cent", default: 0
    t.string "supay_platform"
    t.integer "actual_credit_card_service_amount_in_cent", default: 0
    t.decimal "actual_credit_card_service_percentage", precision: 5, scale: 2, default: "0.0", comment: "实际信用卡服务费百分比"
    t.bigint "warehouse_order_id"
    t.string "express_carrier", comment: "第三方邮寄派送，例如：KUAIMA"
    t.integer "deliver_to_door_service_fee_in_cent", default: 0, comment: "送货上门服务费"
    t.boolean "is_child", default: false, comment: "是否加单的子单"
    t.string "stripe_transaction_id"
    t.datetime "eta", comment: "WMS预计配送时间"
    t.datetime "ata", comment: "WMS实际配送时间"
    t.string "delivery_path", comment: "配送路线"
    t.boolean "ae_drop_shipper", default: false
    t.jsonb "ae_error_response"
    t.string "ae_order_list", array: true
    t.integer "ae_gst_amount_in_cent", default: 0
    t.bigint "delivery_time_period_setting_id"
    t.integer "long_distance_fee_in_cent", default: 0, comment: "远程运费"
    t.integer "time_period_fee_in_cent", default: 0, comment: "指定时间段运费"
    t.integer "box_regulation_fee_in_cent", default: 0, comment: "超出箱规费用"
    t.integer "box_regulation_quantity", default: 0, comment: "箱规数量"
    t.integer "free_box_regulation_quantity", default: 0, comment: "免费箱规数量"
    t.integer "per_box_charge_in_cent", default: 0, comment: "每个箱规费用"
    t.integer "package_service_fee_in_cent", default: 0, comment: "包装服务费"
    t.integer "package_service_discount_in_cent", default: 0, comment: "包装服务费"
    t.integer "original_package_service_fee_in_cent", default: 0, comment: "原始包装服务费"
    t.integer "address_housing_type", default: 1, comment: "地址房屋类型: 1-住宅, 2-公寓, 3-公司"
    t.index ["coupon_id"], name: "index_orders_on_coupon_id", unique: true, where: "(status <> 6)"
    t.index ["created_at"], name: "index_orders_on_created_at"
    t.index ["deleted_by_user_at"], name: "index_orders_on_deleted_by_user_at"
    t.index ["delivery_date"], name: "index_orders_on_delivery_date"
    t.index ["delivery_time_id"], name: "index_orders_on_delivery_time_id"
    t.index ["delivery_time_period_setting_id"], name: "index_orders_on_delivery_time_period_setting_id"
    t.index ["gift_activity_id"], name: "index_orders_on_gift_activity_id"
    t.index ["gift_card_coupon_id"], name: "index_orders_on_gift_card_coupon_id"
    t.index ["gift_coupon_template_id"], name: "index_orders_on_gift_coupon_template_id"
    t.index ["groupon_activity_id"], name: "index_orders_on_groupon_activity_id"
    t.index ["groupon_id"], name: "index_orders_on_groupon_id"
    t.index ["next_day_delivery"], name: "index_orders_on_next_day_delivery"
    t.index ["no"], name: "index_orders_on_no", unique: true
    t.index ["promo_code_id"], name: "index_orders_on_promo_code_id"
    t.index ["province_id"], name: "index_orders_on_province_id"
    t.index ["refund_no"], name: "index_orders_on_refund_no", unique: true
    t.index ["same_day_delivery_time_id"], name: "index_orders_on_same_day_delivery_time_id"
    t.index ["same_day_delivery_time_period_id"], name: "index_orders_on_same_day_delivery_time_period_id"
    t.index ["self_pick_up_id"], name: "index_orders_on_self_pick_up_id"
    t.index ["sku_groupon_id"], name: "index_orders_on_sku_groupon_id"
    t.index ["store_id"], name: "index_orders_on_store_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
    t.index ["warehouse_order_id"], name: "index_orders_on_warehouse_order_id"
  end

  create_table "overseas_student_applications", force: :cascade do |t|
    t.string "nickname"
    t.integer "gender"
    t.date "birthday"
    t.string "school"
    t.string "email"
    t.string "student_number"
    t.string "student_image_obverse_side"
    t.string "student_image_reverse_side"
    t.integer "status", default: 1
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_overseas_student_applications_on_user_id"
  end

  create_table "page_popups", force: :cascade do |t|
    t.string "title"
    t.string "image"
    t.string "path"
    t.boolean "for_new_user", default: false
    t.datetime "start_at"
    t.datetime "end_at"
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "store_id"
    t.boolean "is_always", default: false
    t.boolean "is_fullscreen", default: false
    t.integer "page_type", default: 1
    t.integer "au_suburb_ids", default: [], array: true
    t.string "locales", default: ["zh-CN", "zh-TW"], array: true
    t.index ["store_id"], name: "index_page_popups_on_store_id"
  end

  create_table "pages", force: :cascade do |t|
    t.string "name"
    t.integer "kind"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "cover"
    t.string "desc"
    t.integer "position", default: 0
  end

  create_table "payment_settings", force: :cascade do |t|
    t.bigint "store_id"
    t.float "wechat_service_percentage"
    t.float "vm_credit_card_service_percentage"
    t.float "unionpay_credit_card_service_percentage"
    t.float "exchange_rate_rise_percentage"
    t.float "omipay_wechat_service_percentage"
    t.float "omipay_alipay_service_percentage"
    t.float "supay_wechat_service_percentage"
    t.float "supay_alipay_service_percentage"
    t.boolean "enable_commweb_3ds_auth", default: true
    t.float "apple_pay_service_percentage"
    t.float "cba_apple_pay_service_percentage"
    t.float "cba_google_pay_service_percentage"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "amex_credit_card_service_percentage"
    t.integer "no_transaction_fee_over_amount_in_cent", comment: "实付满金额免手续费，为空时必收手续费"
    t.boolean "display_cba_credit_card_service", default: true
    t.boolean "display_unionpay_credit_card_service", default: true
    t.boolean "display_omipay_wechat_service", default: false
    t.boolean "display_omipay_alipay_service", default: false
    t.boolean "display_supay_wechat_service", default: false
    t.boolean "display_supay_alipay_service", default: false
    t.boolean "display_apple_pay_service", default: true
    t.boolean "display_cba_apple_pay_service", default: true
    t.boolean "display_cba_google_pay_service", default: true
    t.float "stripe_credit_card_service_percentage"
    t.float "stripe_apple_pay_service_percentage"
    t.float "stripe_google_pay_service_percentage"
    t.boolean "display_stripe_credit_card_service", default: false
    t.boolean "display_stripe_apple_pay_service", default: false
    t.boolean "display_stripe_google_pay_service", default: false
    t.index ["store_id"], name: "index_payment_settings_on_store_id"
  end

  create_table "payments", force: :cascade do |t|
    t.string "transaction_id"
    t.decimal "amount_in_cent", precision: 12, scale: 2
    t.string "type"
    t.string "paymentable_type"
    t.bigint "paymentable_id"
    t.integer "status", default: 1
    t.integer "payment_type", default: 1
    t.json "response", default: {}
    t.bigint "parent_id"
    t.decimal "refund_amount_in_cent", precision: 12, scale: 2, default: "0.0"
    t.decimal "refunding_amount_in_cent", precision: 12, scale: 2, default: "0.0"
    t.decimal "service_amount_in_cent", precision: 12, scale: 2, default: "0.0"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "no"
    t.integer "channel", default: 1
    t.string "platform"
    t.index ["parent_id"], name: "index_payments_on_parent_id"
    t.index ["paymentable_type", "paymentable_id"], name: "index_payments_on_paymentable_type_and_paymentable_id"
    t.index ["transaction_id"], name: "index_payments_on_transaction_id"
  end

  create_table "preferential_pool_translations", force: :cascade do |t|
    t.bigint "preferential_pool_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.index ["locale"], name: "index_preferential_pool_translations_on_locale"
    t.index ["preferential_pool_id"], name: "index_preferential_pool_translations_on_preferential_pool_id"
  end

  create_table "preferential_pools", force: :cascade do |t|
    t.integer "kind", default: 1, comment: "优惠类型"
    t.integer "sku_ids", default: [], array: true
    t.integer "threshold_kind", default: 1, comment: "门槛类型"
    t.integer "at_least_amount_in_cent", comment: "门槛金额"
    t.integer "at_least_quantity", comment: "门槛数量"
    t.datetime "start_at", comment: "活动开始时间"
    t.datetime "end_at", comment: "活动结束时间"
    t.json "preferences", default: {}, comment: "优惠内容"
    t.boolean "enabled", default: true, comment: "是否启用"
    t.bigint "store_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_preferential_pools_on_store_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "title"
    t.string "sub_title"
    t.text "description"
    t.string "shared_description"
    t.string "cover"
    t.string "share_cover"
    t.string "main_images", default: [], array: true
    t.string "detail_video"
    t.string "detail_images", default: [], array: true
    t.integer "actual_monthly_sales_count", default: 0, null: false
    t.bigint "category_id"
    t.bigint "brand_id"
    t.bigint "store_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "monthly_sales_count_offset", default: 0
    t.bigint "qa_and_guarantee_id"
    t.integer "sales_count_offset", default: 0
    t.integer "items_count", default: 0
    t.integer "minor_category_id"
    t.string "short_title"
    t.index ["brand_id"], name: "index_products_on_brand_id"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["minor_category_id"], name: "index_products_on_minor_category_id"
    t.index ["qa_and_guarantee_id"], name: "index_products_on_qa_and_guarantee_id"
    t.index ["store_id"], name: "index_products_on_store_id"
  end

  create_table "promo_code_templates", force: :cascade do |t|
    t.bigint "store_id"
    t.string "title"
    t.boolean "enabled", default: false
    t.date "start_on"
    t.date "end_on"
    t.string "remark"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "display_in_item_detail", default: false
    t.integer "user_kind", default: 1, comment: "用户类型，1为全部用户，2为新用户"
    t.integer "use_times_kind", default: 1, comment: "使用次数类型，1为不限，2为每人限用1次"
    t.integer "purpose", default: 1, comment: "用途"
    t.index ["store_id"], name: "index_promo_code_templates_on_store_id"
  end

  create_table "promo_codes", force: :cascade do |t|
    t.string "code"
    t.bigint "order_id"
    t.bigint "promo_code_template_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "store_id"
    t.integer "total_avaliable_count", default: 1, null: false
    t.integer "used_count", default: 0, null: false
    t.index ["order_id"], name: "index_promo_codes_on_order_id"
    t.index ["promo_code_template_id", "code"], name: "index_promo_codes_on_promo_code_template_id_and_code", unique: true
    t.index ["promo_code_template_id"], name: "index_promo_codes_on_promo_code_template_id"
  end

  create_table "promo_stock_keeping_units", force: :cascade do |t|
    t.bigint "promo_code_template_id"
    t.bigint "stock_keeping_unit_id"
    t.integer "price_in_cent", comment: "SKU 单价"
    t.integer "quantity", comment: "SKU 数量"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["promo_code_template_id"], name: "index_promo_stock_keeping_units_on_promo_code_template_id"
    t.index ["stock_keeping_unit_id"], name: "index_promo_stock_keeping_units_on_stock_keeping_unit_id"
  end

  create_table "provinces", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "kind", default: 1
    t.string "code"
  end

  create_table "push_message_read_logs", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "push_message_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "details_viewed", default: false
    t.index ["push_message_id"], name: "index_push_message_read_logs_on_push_message_id"
    t.index ["user_id", "push_message_id"], name: "index_push_message_read_logs_on_user_id_and_push_message_id", unique: true
    t.index ["user_id"], name: "index_push_message_read_logs_on_user_id"
  end

  create_table "push_messages", force: :cascade do |t|
    t.bigint "admin_user_id"
    t.string "title"
    t.text "content"
    t.integer "state", default: 0
    t.datetime "push_at"
    t.integer "uv", default: 0
    t.integer "pv", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "image"
    t.bigint "store_id"
    t.integer "kind", default: 0
    t.boolean "path_customized", default: false
    t.string "path_customized_type"
    t.bigint "path_customized_id"
    t.integer "user_ids", default: [], array: true
    t.string "user_locales", default: ["zh-CN", "zh-TW"], array: true
    t.index ["admin_user_id"], name: "index_push_messages_on_admin_user_id"
    t.index ["path_customized_id", "path_customized_type"], name: "index_push_messages_on_path_customized_attrs"
    t.index ["store_id"], name: "index_push_messages_on_store_id"
  end

  create_table "qa_and_guarantee_translations", force: :cascade do |t|
    t.bigint "qa_and_guarantee_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "image"
    t.string "title"
    t.index ["locale"], name: "index_qa_and_guarantee_translations_on_locale"
    t.index ["qa_and_guarantee_id"], name: "index_qa_and_guarantee_translations_on_qa_and_guarantee_id"
  end

  create_table "qa_and_guarantees", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "web_image"
  end

  create_table "random_reduction_coupon_template_rules", force: :cascade do |t|
    t.integer "min_amount_in_cent", default: 0, null: false
    t.integer "max_amount_in_cent", default: 0, null: false
    t.integer "max_quantity", default: 0, null: false
    t.integer "used_quantity", default: 0, null: false
    t.bigint "coupon_template_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["coupon_template_id"], name: "index_random_reduction_rules_on_coupon_template_id"
  end

  create_table "report_pages", force: :cascade do |t|
    t.string "name", null: false
    t.text "content", null: false
    t.integer "creator_id", null: false
    t.integer "admin_user_ids", default: [], comment: "可查看的管理员用户", array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_report_pages_on_creator_id"
  end

  create_table "role_templates", force: :cascade do |t|
    t.string "name"
    t.string "permissions", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "same_day_delivery_cart_items", force: :cascade do |t|
    t.integer "quantity", default: 1
    t.bigint "same_day_delivery_cart_id"
    t.bigint "stock_keeping_unit_id"
    t.datetime "deleted_at"
    t.bigint "store_id"
    t.integer "source_page_name"
    t.integer "source_channel"
    t.integer "source_custom_list_id"
    t.json "source_extra_hash"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["same_day_delivery_cart_id", "stock_keeping_unit_id"], name: "index_same_day_cart_items_on_shopping_cart_id_and_sku_id", unique: true
    t.index ["same_day_delivery_cart_id"], name: "index_same_day_cart_items_on_shopping_cart_id"
    t.index ["source_custom_list_id"], name: "index_same_day_cart_items_on_source_custom_list_id"
    t.index ["stock_keeping_unit_id"], name: "index_same_day_cart_items_on_stock_keeping_unit_id"
    t.index ["store_id"], name: "index_same_day_delivery_cart_items_on_store_id"
  end

  create_table "same_day_delivery_carts", force: :cascade do |t|
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_same_day_delivery_carts_on_user_id"
  end

  create_table "same_day_delivery_time_periods", force: :cascade do |t|
    t.string "time_period"
    t.integer "kind"
    t.integer "time_window"
    t.integer "address_count_limit"
    t.boolean "enabled", default: true
    t.bigint "same_day_delivery_time_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "free_shipping_amount_in_cent", comment: "免额外运费门槛"
    t.integer "extra_shipping_amount_in_cent", comment: "额外运费"
    t.index ["same_day_delivery_time_id"], name: "index_delivery_time_periods_on_same_day_delivery_time_id"
  end

  create_table "same_day_delivery_times", force: :cascade do |t|
    t.string "name"
    t.string "weekdays", default: [], array: true
    t.boolean "limited_by_orders_limit_every_day", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "self_pick_order_date_analyses", force: :cascade do |t|
    t.integer "self_pick_up_id"
    t.date "delivery_date"
    t.integer "orders_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_date", "self_pick_up_id"], name: "self_pick_order_on_delivery_date_and_self_pick_up", unique: true
  end

  create_table "self_pick_ups", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "address"
    t.string "mobile"
    t.string "google_place_id"
    t.string "province_name"
    t.string "city_name"
    t.string "street"
    t.string "street_number"
    t.string "opening_hours", comment: "营业时间"
    t.string "postal_code"
    t.float "latitude"
    t.float "longitude"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "store_id"
    t.string "weekdays", default: [], array: true
    t.string "time_period", default: [], array: true
    t.integer "self_pick_orders_limit_every_day", default: 0
    t.boolean "enabled", default: true
    t.boolean "support_same_day_delivery", default: false
    t.index ["store_id"], name: "index_self_pick_ups_on_store_id"
  end

  create_table "share_settings", force: :cascade do |t|
    t.string "share_background_cover"
    t.string "share_words"
    t.string "share_cover"
    t.string "target_type"
    t.bigint "target_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "store_id"
    t.string "search_words"
    t.string "search_cover"
    t.index ["store_id"], name: "index_share_settings_on_store_id"
    t.index ["target_type", "target_id"], name: "index_share_settings_on_target_type_and_target_id"
  end

  create_table "shopline_users", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reset_password_token"
    t.string "reset_email_token"
    t.string "shopline_user_id"
    t.jsonb "addresses"
    t.string "reset_phone_token"
  end

  create_table "shopping_cart_items", force: :cascade do |t|
    t.integer "quantity", default: 1
    t.bigint "shopping_cart_id"
    t.bigint "stock_keeping_unit_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.bigint "store_id"
    t.integer "source_page_name"
    t.integer "source_channel"
    t.integer "source_custom_list_id"
    t.json "source_extra_hash"
    t.boolean "live_top", default: false
    t.index ["shopping_cart_id", "stock_keeping_unit_id"], name: "index_cart_items_on_shopping_cart_id_and_sku_id", unique: true
    t.index ["shopping_cart_id"], name: "index_shopping_cart_items_on_shopping_cart_id"
    t.index ["source_custom_list_id"], name: "index_shopping_cart_items_on_source_custom_list_id"
    t.index ["stock_keeping_unit_id"], name: "index_shopping_cart_items_on_stock_keeping_unit_id"
    t.index ["store_id"], name: "index_shopping_cart_items_on_store_id"
  end

  create_table "shopping_carts", force: :cascade do |t|
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_shopping_carts_on_user_id"
  end

  create_table "shortened_scenes", force: :cascade do |t|
    t.string "scene"
    t.string "short_scene"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["short_scene"], name: "index_shortened_scenes_on_short_scene"
  end

  create_table "sign_in_activities", force: :cascade do |t|
    t.string "detail_image"
    t.datetime "start_at"
    t.datetime "end_at"
    t.boolean "enabled", default: true, comment: "是否启用"
    t.integer "reward_integral_each_time", comment: "单次签到金币"
    t.integer "extra_reward_type", default: 1, comment: "额外奖励计算方式"
    t.integer "sign_in_times", comment: "签到次数"
    t.integer "extra_reward_integral", comment: "额外金币"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "banner"
  end

  create_table "sign_in_activity_translations", force: :cascade do |t|
    t.bigint "sign_in_activity_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.index ["locale"], name: "index_sign_in_activity_translations_on_locale"
    t.index ["sign_in_activity_id"], name: "index_sign_in_activity_translations_on_sign_in_activity_id"
  end

  create_table "sign_in_histories", force: :cascade do |t|
    t.bigint "sign_in_activity_id"
    t.bigint "user_id"
    t.date "sign_in_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sign_in_activity_id", "user_id", "sign_in_date"], name: "index_sign_in_histories_on_user_and_activity_and_sign_in_date", unique: true
    t.index ["sign_in_activity_id"], name: "index_sign_in_histories_on_sign_in_activity_id"
    t.index ["user_id"], name: "index_sign_in_histories_on_user_id"
  end

  create_table "sign_in_reward_histories", force: :cascade do |t|
    t.bigint "sign_in_activity_id"
    t.bigint "sign_in_history_id"
    t.bigint "user_id"
    t.integer "reward_type", default: 1
    t.integer "integral"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sign_in_activity_id"], name: "index_sign_in_reward_histories_on_sign_in_activity_id"
    t.index ["sign_in_history_id"], name: "index_sign_in_reward_histories_on_sign_in_history_id"
    t.index ["user_id"], name: "index_sign_in_reward_histories_on_user_id"
  end

  create_table "site_configs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "customer_service_name"
    t.json "web_home_banners", default: []
    t.string "web_item_list_images", default: [], array: true
    t.string "web_welcome_image"
    t.json "mall_tips"
    t.string "direct_refund_reasons", default: [], array: true
    t.string "after_sale_reasons", default: [], array: true
    t.json "return_receiver_properties"
    t.string "member_bg_image"
    t.string "order_analyses_notify_emails", default: [], array: true
    t.json "order_configs", default: {}
    t.json "web_item_list_video", default: {}
    t.json "web_event_list_video", default: {}
    t.json "web_welcome_video", default: {}
    t.json "integral_rules", default: {}
    t.json "payment_settings", default: {}
    t.integer "stock_short_quantity"
    t.string "android_sms_public_url"
    t.string "android_sms_notification_emails", default: [], array: true
    t.json "watermark_attributes", default: {}
    t.string "user_default_avatar"
    t.string "cutoff_time", default: [], array: true
    t.bigint "store_id"
    t.json "app_version"
    t.integer "config_type", default: 1
    t.datetime "sms_first_phone_send_at"
    t.datetime "sms_second_phone_send_at"
    t.json "base", default: {}
    t.integer "invited_coupon_template_id"
    t.integer "newbie_coupon_template_ids", default: [], array: true
    t.string "customer_services", default: [], array: true
    t.integer "merchant_delivery_orders_limit_every_day", default: 0, comment: "每日地址数配送上限"
    t.boolean "enable_commweb_3ds_auth", default: false
    t.integer "merchant_delivery_total_orders_limit_every_day", default: 0, comment: "每日总订单配送上限"
    t.boolean "allow_comments", default: true
    t.string "cart_empty_image"
    t.boolean "order_creation_disabled", default: false
    t.string "order_creation_disabled_tips"
    t.integer "finish_order_coupon_template_ids_to_inviter", default: [], array: true
    t.json "delivery_type_settings", default: {}
    t.string "search_placeholder"
    t.json "integral_special_period_rule", default: {}
    t.string "order_buyer_message_placeholder"
    t.json "invitation", default: {}
    t.decimal "sku_cost_minimum_factor", default: "1.3", null: false
    t.string "sku_price_exception_emails", default: [], array: true
    t.integer "new_user_custom_page_id"
    t.text "new_user_message_text"
    t.integer "invited_coupon_template_ids", default: [], array: true
    t.string "custom_time_zone"
    t.boolean "order_finished_reward_integral", default: true
    t.integer "sku_minimum_profit_in_cent"
    t.boolean "risk_pay_enabled", default: false
    t.json "same_day_delivery_cutoff_time", default: {}
    t.integer "info_finished_coupon_template_id"
    t.integer "birthday_coupon_template_id"
    t.json "value_added_service_settings", default: {}, comment: "增值服务开关配置"
    t.integer "kuaima_delivery_max_count", default: 0, comment: "每天快马配送最大数量"
    t.integer "web_newbie_coupon_template_ids", default: [], array: true
    t.integer "web_invited_coupon_template_ids", default: [], array: true
    t.integer "web_finish_order_coupon_template_ids_to_inviter", default: [], array: true
    t.integer "web_info_finished_coupon_template_id"
    t.integer "web_birthday_coupon_template_id"
    t.boolean "auction_enabled", default: true, comment: "控制APP我的拍卖入口显示"
    t.decimal "shopline_price_rate", precision: 10, scale: 2, default: "1.2", comment: "Shopline价格倍率"
    t.boolean "shopline_order_creation_disabled", default: false
    t.jsonb "bottom_settings", default: {}
    t.string "payment_callback_timeout_emails", default: [], array: true
    t.decimal "ae_sku_cost_minimum_factor", default: "1.3", null: false
    t.integer "ae_order_gst_percent", default: 10
    t.jsonb "go_back_to_ebest_right_icon_settings", default: {}, comment: "回到自营页右侧图标设置"
    t.jsonb "go_back_to_ebest_category_icon_settings", default: {}, comment: "回到自营页分类图标设置"
    t.jsonb "go_back_to_ebest_bottom_icon_settings", default: {}, comment: "回到自营页底部图标设置"
    t.jsonb "order_box_regulation_settings", default: {}
    t.jsonb "order_package_settings", default: {}
    t.string "sms_platform", default: "nxcloud", null: false, comment: "短信发送平台"
    t.index ["store_id"], name: "index_site_configs_on_store_id"
  end

  create_table "sku_groupons", force: :cascade do |t|
    t.bigint "stock_keeping_unit_id"
    t.bigint "groupon_activity_id"
    t.bigint "item_id"
    t.integer "price_in_cent", comment: "商品拼团价格"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "enabled", default: true
    t.index ["groupon_activity_id", "stock_keeping_unit_id"], name: "index_sku_groupons_on_groupon_activity_and_stock_keeping_unit", unique: true
    t.index ["groupon_activity_id"], name: "index_sku_groupons_on_groupon_activity_id"
    t.index ["item_id"], name: "index_sku_groupons_on_item_id"
    t.index ["stock_keeping_unit_id"], name: "index_sku_groupons_on_stock_keeping_unit_id"
  end

  create_table "sku_in_stock_notices", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "stock_keeping_unit_id"
    t.integer "state", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stock_keeping_unit_id"], name: "index_sku_in_stock_notices_on_stock_keeping_unit_id"
    t.index ["user_id"], name: "index_sku_in_stock_notices_on_user_id"
  end

  create_table "sku_inventory_snapshots", force: :cascade do |t|
    t.bigint "stock_keeping_unit_id"
    t.date "record_date"
    t.integer "quantity", default: 0
    t.integer "reserved_quantity", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stock_keeping_unit_id", "record_date"], name: "sku_inventory_snapshots_on_sku_id_and_record_date", unique: true
    t.index ["stock_keeping_unit_id"], name: "index_sku_inventory_snapshots_on_stock_keeping_unit_id"
  end

  create_table "sku_properties", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ae_property_id"
    t.index ["ae_property_id"], name: "index_sku_properties_on_ae_property_id"
  end

  create_table "sku_property_translations", force: :cascade do |t|
    t.bigint "sku_property_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "text"
    t.index ["locale"], name: "index_sku_property_translations_on_locale"
    t.index ["sku_property_id"], name: "index_sku_property_translations_on_sku_property_id"
  end

  create_table "sku_sales_mailer_settings", force: :cascade do |t|
    t.string "title", comment: "邮件标题"
    t.string "receiver_emails", comment: "接收邮件的邮箱，多个邮箱用分号分隔"
    t.string "cc_emails", comment: "抄送邮件的邮箱，多个邮箱用分号分隔"
    t.integer "deliver_after_n_days", comment: "N天后发货的统计，例：设置1则统计发货日期为一天后的数据"
    t.boolean "contains_order_gift", comment: "是否包含订单赠品"
    t.boolean "contains_order_pool_gift", comment: "是否包含订单池赠品"
    t.string "send_at", comment: "发送时间，格式：HH:MM:SS"
    t.integer "send_frequency", comment: "发送频率，1: 单次，2: 每天，3: 每周"
    t.string "weekdays", default: [], comment: "每周发送的日期，0: 周日, 1: 周一，2: 周二，3: 周三，4: 周四，5: 周五，6: 周六", array: true
    t.integer "sku_search_type", comment: "sku搜索类型，1: 根据条件，2: 根据sku_ids"
    t.json "sku_search_conditions", default: {}, comment: "sku搜索条件"
    t.integer "sku_ids", default: [], array: true
    t.boolean "enabled", default: false, comment: "是否启用"
    t.bigint "store_id", comment: "店铺"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "skip_zero_sales_skus", default: true, comment: "是否过滤掉销量为0的sku"
    t.index ["store_id"], name: "index_sku_sales_mailer_settings_on_store_id"
  end

  create_table "sku_valid_inventory_dates", force: :cascade do |t|
    t.bigint "stock_keeping_unit_id"
    t.date "date", null: false
    t.bigint "store_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stock_keeping_unit_id"], name: "index_sku_valid_inventory_dates_on_stock_keeping_unit_id"
    t.index ["store_id"], name: "index_sku_valid_inventory_dates_on_store_id"
  end

  create_table "sku_value_translations", force: :cascade do |t|
    t.bigint "sku_value_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "text"
    t.index ["locale"], name: "index_sku_value_translations_on_locale"
    t.index ["sku_value_id"], name: "index_sku_value_translations_on_sku_value_id"
  end

  create_table "sku_values", force: :cascade do |t|
    t.bigint "sku_property_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ae_property_value_id"
    t.index ["sku_property_id", "ae_property_value_id"], name: "index_sku_values_on_sku_property_id_and_ae_property_value_id"
    t.index ["sku_property_id"], name: "index_sku_values_on_sku_property_id"
  end

  create_table "stock_keeping_units", force: :cascade do |t|
    t.string "properties"
    t.integer "quantity", default: 0
    t.integer "price_in_cent", default: 0
    t.string "image"
    t.integer "position", default: 0
    t.integer "comments_count", default: 0
    t.bigint "item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "weight_in_gram", default: 0, null: false
    t.integer "cost_price_in_cent", default: 0
    t.string "no"
    t.json "groups", default: []
    t.float "height_in_cm", default: 0.0
    t.float "width_in_cm", default: 0.0
    t.float "length_in_cm", default: 0.0
    t.string "barcode"
    t.integer "strikethrough_price_in_cent"
    t.boolean "on_sale", default: true
    t.bigint "store_id"
    t.integer "carton_size", default: 0
    t.integer "pending_in_stock_notices_count", default: 0
    t.integer "gst_percent", default: 0
    t.integer "marketing_mode", default: 1
    t.boolean "is_special", default: false
    t.boolean "is_private_kitchen", default: false, comment: "是否私厨"
    t.string "shoppingunit", comment: "入驻商"
    t.integer "discount_quantity"
    t.integer "discount_price_in_cent"
    t.integer "new_user_price_in_cent"
    t.integer "new_user_buy_quota", default: 0, comment: "新人限购数量，0为不限"
    t.string "sku_level"
    t.integer "can_cover_weeks"
    t.boolean "can_create_invoice", default: true
    t.decimal "nominal_gross_margin_ratio", precision: 12, scale: 2, default: "0.0", comment: "名义毛利率"
    t.string "gmv_sku_level"
    t.string "gp_sku_level"
    t.decimal "turnover_rate", precision: 12, scale: 2, comment: "周转率"
    t.datetime "first_sale_at", comment: "首次上架开卖时间"
    t.integer "shopline_price_in_cent", default: 0
    t.integer "ae_price_in_cent", default: 0
    t.boolean "aws_lambda_image_generated", default: false
    t.string "ae_sku_attr"
    t.boolean "is_box_regulation", default: false
    t.index ["barcode", "store_id"], name: "index_stock_keeping_units_on_barcode_and_store_id", unique: true
    t.index ["created_at"], name: "index_stock_keeping_units_on_created_at"
    t.index ["id", "item_id"], name: "index_stock_keeping_units_on_id_and_item_id"
    t.index ["item_id", "properties"], name: "index_stock_keeping_units_on_item_id_and_properties", unique: true
    t.index ["item_id"], name: "index_stock_keeping_units_on_item_id"
    t.index ["no", "store_id"], name: "index_stock_keeping_units_on_no_and_store_id", unique: true
    t.index ["store_id"], name: "index_stock_keeping_units_on_store_id"
  end

  create_table "stores", force: :cascade do |t|
    t.string "name"
    t.boolean "is_default", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "bg_color", default: "#C5EDE7"
    t.string "short_name"
    t.integer "default_au_suburb_id"
    t.boolean "disabled", default: false, comment: "是否停用门店"
    t.index ["default_au_suburb_id"], name: "index_stores_on_default_au_suburb_id"
    t.index ["short_name"], name: "index_stores_on_short_name", unique: true
  end

  create_table "subscribe_records", force: :cascade do |t|
    t.string "targetable_type"
    t.bigint "targetable_id"
    t.string "template_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["targetable_type", "targetable_id"], name: "index_subscribe_records_on_targetable_type_and_targetable_id"
    t.index ["user_id"], name: "index_subscribe_records_on_user_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "name"
    t.integer "cost_in_cent"
    t.bigint "stock_keeping_unit_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "include_gst", default: false
    t.decimal "gst_amount", precision: 12, scale: 2
    t.index ["stock_keeping_unit_id"], name: "index_suppliers_on_stock_keeping_unit_id"
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.string "taggable_type"
    t.integer "taggable_id"
    t.string "tagger_type"
    t.integer "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at"
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "third_party_categories", force: :cascade do |t|
    t.string "third_party_id"
    t.integer "third_party_type", comment: "第三方平台类型: 1: shopline, 2: aliexpress"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "category_id"
    t.index ["category_id"], name: "index_third_party_categories_on_category_id"
    t.index ["third_party_id"], name: "index_third_party_categories_on_third_party_id"
  end

  create_table "third_party_items", force: :cascade do |t|
    t.bigint "item_id"
    t.string "third_party_id"
    t.integer "third_party_type", comment: "第三方平台类型: 1: shopline, 2: aliexpress"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id", "third_party_type"], name: "index_third_party_items_on_item_id_and_third_party_type", unique: true
    t.index ["item_id"], name: "index_third_party_items_on_item_id"
    t.index ["third_party_id"], name: "index_third_party_items_on_third_party_id"
  end

  create_table "third_party_orders", force: :cascade do |t|
    t.integer "third_party_type", comment: "第三方平台类型: 1: shopline, 2: aliexpress"
    t.string "third_party_id", comment: "第三方平台订单id"
    t.string "no", comment: "第三方平台订单号"
    t.string "status", comment: "状态: open 处理中，cancelled 已取消"
    t.string "financial_status", comment: "支付状态"
    t.string "fulfillment_status", comment: "发货状态"
    t.integer "delivery_type", default: 1
    t.integer "sync_status", default: 1, comment: "同步到 wms 状态"
    t.datetime "synced_at", comment: "同步到 wms 时间"
    t.string "delivery_date", comment: "配送日期"
    t.string "prefer_time", comment: "配送时间段"
    t.decimal "order_total", precision: 10, scale: 2, comment: "订单支付金额"
    t.decimal "total_discounts", precision: 10, scale: 2, comment: "折扣金额"
    t.decimal "total_line_items_price", precision: 10, scale: 2, comment: "商品总价"
    t.jsonb "order_items", comment: "订单商品"
    t.jsonb "payment_details", default: {}, comment: "支付详情"
    t.jsonb "receiver_properties", default: {}, null: false, comment: "收货人信息"
    t.string "buyer_message", comment: "买家留言"
    t.jsonb "shipping_lines", default: {}, null: false, comment: "运费信息"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "store_id"
    t.bigint "warehouse_order_id"
    t.jsonb "refunds"
    t.string "delivery_path", comment: "配送路线"
    t.string "delivery_track", comment: "物流追踪"
    t.datetime "eta"
    t.datetime "ata"
    t.boolean "inventory_returned", default: false, comment: "是否已回退库存"
    t.string "tracking_no"
    t.string "customer_id"
    t.index ["store_id"], name: "index_third_party_orders_on_store_id"
    t.index ["warehouse_order_id"], name: "index_third_party_orders_on_warehouse_order_id"
  end

  create_table "third_party_skus", force: :cascade do |t|
    t.bigint "stock_keeping_unit_id"
    t.string "third_party_id"
    t.integer "third_party_type", comment: "第三方平台类型: 1: shopline, 2: aliexpress"
    t.string "third_party_inventory_item_id", comment: "库存id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stock_keeping_unit_id", "third_party_type"], name: "index_third_party_skus_on_sku_id_and_type", unique: true
    t.index ["stock_keeping_unit_id"], name: "index_third_party_skus_on_stock_keeping_unit_id"
    t.index ["third_party_id"], name: "index_third_party_skus_on_third_party_id"
  end

  create_table "third_party_users", force: :cascade do |t|
    t.integer "third_party_type", comment: "第三方平台类型: 1: shopline, 2: aliexpress"
    t.string "third_party_id"
    t.string "email"
    t.bigint "store_id"
    t.string "first_name"
    t.string "last_name"
    t.string "nick_name"
    t.string "gender"
    t.string "phone"
    t.string "total_spent"
    t.integer "orders_count"
    t.text "note"
    t.integer "state", comment: "0: 已禁用账户, 1: 待启用账户, 2: 已邀请账户, 3: 有效账户"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_third_party_users_on_store_id"
  end

  create_table "time_limited_promotion_prices", force: :cascade do |t|
    t.bigint "time_limited_promotion_id"
    t.bigint "stock_keeping_unit_id"
    t.integer "price_in_cent", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "start_at"
    t.datetime "end_at"
    t.boolean "enabled", default: false
    t.bigint "store_id"
    t.integer "quantity", comment: "优惠价库存"
    t.integer "reserved_quantity", comment: "预留的原价库存"
    t.integer "original_buy_quota", default: 0
    t.integer "original_buy_quota_days", default: 0
    t.integer "buy_quota", default: 0
    t.integer "buy_quota_days", default: 1
    t.datetime "quantity_updated_at"
    t.integer "position", comment: "权重，值越小，排序越靠前"
    t.index ["stock_keeping_unit_id"], name: "index_time_limited_promotion_prices_on_sku_id"
    t.index ["store_id", "enabled"], name: "index_time_limited_promotion_prices_on_store_id_and_enabled"
    t.index ["store_id"], name: "index_time_limited_promotion_prices_on_store_id"
    t.index ["time_limited_promotion_id"], name: "index_time_limited_promotion_prices_on_tlp_id"
  end

  create_table "time_limited_promotions", force: :cascade do |t|
    t.string "title", null: false
    t.datetime "start_at", null: false
    t.datetime "end_at", null: false
    t.boolean "enabled", default: false
    t.bigint "store_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "state", default: 0, null: false
    t.boolean "save_qty_to_promotion_price", default: false, comment: "限时优惠活动期间添加库存到优惠库存"
    t.index ["store_id"], name: "index_time_limited_promotions_on_store_id"
  end

  create_table "top_left_item_tags", force: :cascade do |t|
    t.string "name"
    t.string "icon"
    t.integer "item_ids", default: [], array: true
    t.datetime "start_at"
    t.datetime "end_at"
    t.bigint "store_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_top_left_item_tags_on_store_id"
  end

  create_table "user_histories", force: :cascade do |t|
    t.bigint "user_id"
    t.string "operatable_type"
    t.bigint "operatable_id"
    t.date "view_date"
    t.integer "count", default: 0
    t.integer "channel", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["operatable_type", "operatable_id"], name: "index_user_histories_on_operatable_type_and_operatable_id"
    t.index ["user_id"], name: "index_user_histories_on_user_id"
  end

  create_table "user_recommended_products", force: :cascade do |t|
    t.bigint "user_id"
    t.string "mobile", comment: "手机号"
    t.text "recommended_products", comment: "推荐的商品"
    t.string "wechat", comment: "微信号"
    t.string "images", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_recommended_products_on_user_id"
  end

  create_table "user_suggestions", force: :cascade do |t|
    t.text "content"
    t.integer "status", default: 1
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "channel", default: 1
    t.text "reply"
    t.string "images", default: [], array: true
    t.datetime "replied_at"
    t.index ["user_id"], name: "index_user_suggestions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "nickname"
    t.string "avatar"
    t.string "mobile"
    t.string "open_id"
    t.integer "gender"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "valid_orders_count", default: 0
    t.integer "items_viewed_count", default: 0, null: false
    t.string "session_key"
    t.boolean "new_user", default: true
    t.string "unionid"
    t.string "official_open_id", comment: "公众号 oepnid"
    t.boolean "subscribe"
    t.string "app_open_id"
    t.string "ebest_platform_unionid"
    t.string "deleted_mini_open_id"
    t.boolean "is_blocked", default: false
    t.datetime "synce_from_fresh_at"
    t.bigint "selected_store_id"
    t.string "origin_nickname"
    t.integer "origin_gender"
    t.string "origin_avatar"
    t.string "current_visit_ip"
    t.string "last_visit_ip"
    t.datetime "current_visit_at"
    t.datetime "last_visit_at"
    t.string "aus_mp_open_id", comment: "EBEST PTY LTD 主体小程序 Open ID"
    t.string "aus_mp_session_key", comment: "EBEST PTY LTD 主体小程序 session key"
    t.boolean "is_host"
    t.text "app_recent_item_search_words", default: [], array: true
    t.datetime "deleted_by_user_at"
    t.string "locale", default: "zh-CN"
    t.boolean "is_overseas_student", default: false
    t.date "overseas_student_expiration_date"
    t.string "password_digest"
    t.boolean "all_info_finished", default: false
    t.integer "sign_up_channel", default: 2
    t.json "guess_you_like_item_ids_hash", default: {}, comment: "猜你喜欢的商品, 例: { \"store-1-app\": [1,2,3] }"
    t.text "web_recent_item_search_words", default: [], comment: "Web最近搜索的商品关键词", array: true
    t.text "mini_program_recent_item_search_words", default: [], comment: "小程序最近搜索的商品关键词", array: true
    t.string "fingerprint_signatures", default: [], comment: "指纹签名", array: true
    t.boolean "accept_marketing_message", default: true, comment: "是否接收营销短信"
    t.string "branch_io_campaign"
    t.string "branch_io_channel"
    t.string "branch_io_feature"
    t.json "branch_io_extra_hash"
    t.string "app_version"
    t.index ["aus_mp_open_id"], name: "index_users_on_aus_mp_open_id", unique: true
    t.index ["ebest_platform_unionid"], name: "index_users_on_ebest_platform_unionid", unique: true
    t.index ["selected_store_id"], name: "index_users_on_selected_store_id"
    t.index ["unionid"], name: "index_users_on_unionid", unique: true
  end

  create_table "users_push_messages", force: :cascade do |t|
    t.bigint "push_message_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["push_message_id"], name: "index_users_push_messages_on_push_message_id"
    t.index ["user_id"], name: "index_users_push_messages_on_user_id"
  end

  create_table "warehouse_orders", force: :cascade do |t|
    t.string "no", null: false, comment: "仓储订单号，W开头"
    t.jsonb "receiver_properties", default: {}, null: false, comment: "收货人信息"
    t.integer "sync_status", default: 2, null: false, comment: "同步到 wms 状态"
    t.integer "delivery_type", null: false, comment: "配送方式"
    t.string "delivery_date", null: false, comment: "配送日期"
    t.bigint "user_id"
    t.string "delivery_track", comment: "配送物流 URL"
    t.string "prefer_time", null: false, comment: "配送时间段"
    t.boolean "deliver_to_door", null: false, comment: "是否送货上门"
    t.boolean "authority_to_leave", null: false, comment: "是否无人签收"
    t.string "buyer_message", comment: "买家备注，多个销售订单买家备注拼接"
    t.string "remark", comment: "卖家备注，多个销售订单卖家备注拼接"
    t.bigint "store_id"
    t.integer "channel", comment: "订单渠道"
    t.string "express_carrier", comment: "第三方邮寄派送，例如：KUAIMA"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "same_day_delivery", default: false
    t.integer "delivery_time_period_setting_id"
    t.index ["store_id"], name: "index_warehouse_orders_on_store_id"
    t.index ["user_id"], name: "index_warehouse_orders_on_user_id"
  end

  create_table "web_banner_items", force: :cascade do |t|
    t.bigint "web_banner_id"
    t.integer "position", default: 1, null: false
    t.string "mobile_image_url", null: false
    t.string "desktop_image_url", null: false
    t.datetime "start_at"
    t.datetime "end_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "nav_path_type"
    t.bigint "nav_path_id"
    t.json "nav_path"
    t.index ["web_banner_id"], name: "index_web_banner_items_on_web_banner_id"
  end

  create_table "web_banners", force: :cascade do |t|
    t.integer "page_location", null: false
    t.string "remark"
    t.boolean "displayed", default: false
    t.bigint "store_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_web_banners_on_store_id"
  end

  create_table "web_categories", force: :cascade do |t|
    t.bigint "parent_id"
    t.integer "status", default: 1, null: false
    t.integer "position", default: 0, null: false
    t.string "icon"
    t.string "bg_color"
    t.integer "display_length", default: 5
    t.string "filter_icon"
    t.boolean "can_create_invoice", default: true
    t.integer "sort_item_ids", default: [], array: true
    t.boolean "need_age_verification", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "search_keywords", comment: "搜索关键词, 用于提升搜索商品准确度"
    t.index ["parent_id"], name: "index_web_categories_on_parent_id"
  end

  create_table "web_category_translations", force: :cascade do |t|
    t.bigint "web_category_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["locale"], name: "index_web_category_translations_on_locale"
    t.index ["web_category_id"], name: "index_web_category_translations_on_web_category_id"
  end

  create_table "web_custom_list_items", force: :cascade do |t|
    t.bigint "web_custom_list_id"
    t.bigint "item_id"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_web_custom_list_items_on_item_id"
    t.index ["web_custom_list_id"], name: "index_web_custom_list_items_on_web_custom_list_id"
  end

  create_table "web_custom_list_translations", force: :cascade do |t|
    t.bigint "web_custom_list_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.index ["locale"], name: "index_web_custom_list_translations_on_locale"
    t.index ["web_custom_list_id"], name: "index_web_custom_list_translations_on_web_custom_list_id"
  end

  create_table "web_custom_lists", force: :cascade do |t|
    t.integer "position", default: 1
    t.boolean "displayed", default: false
    t.boolean "items_shuffled", default: false
    t.bigint "store_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "page_location", default: 1, null: false
    t.integer "orientation", default: 1, null: false, comment: "1: 横向, 2: 竖向"
    t.index ["store_id"], name: "index_web_custom_lists_on_store_id"
  end

  create_table "web_items", force: :cascade do |t|
    t.string "upper_images", default: [], array: true
    t.string "lower_images", default: [], array: true
    t.string "banner_images", default: [], array: true
    t.bigint "item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "video", default: {}
    t.index ["item_id"], name: "index_web_items_on_item_id"
  end

  create_table "wms_inventories", force: :cascade do |t|
    t.integer "store_id"
    t.integer "product_id"
    t.integer "jerry_sku_id"
    t.integer "inventory_type"
    t.string "area"
    t.string "location"
    t.datetime "expiry_date"
    t.integer "qty"
    t.datetime "updated_at"
  end

  add_foreign_key "admin_users", "admin_users", column: "creator_id"
  add_foreign_key "after_sales_order_items", "after_sales"
  add_foreign_key "after_sales_order_items", "order_items"
  add_foreign_key "age_verifications", "categories", column: "parent_category_id"
  add_foreign_key "age_verifications", "web_categories", column: "parent_web_category_id"
  add_foreign_key "app_text_messages", "admin_users"
  add_foreign_key "app_text_messages", "users"
  add_foreign_key "auction_activities", "auction_automatic_bids", column: "best_automatic_bid_id"
  add_foreign_key "auction_activities", "auction_bids", column: "best_bid_id"
  add_foreign_key "auction_activities", "brands"
  add_foreign_key "auction_activities", "items"
  add_foreign_key "auction_activities", "orders"
  add_foreign_key "auction_activities", "qa_and_guarantees"
  add_foreign_key "auction_activities", "stock_keeping_units"
  add_foreign_key "auction_activities", "stores"
  add_foreign_key "auction_activity_participations", "auction_activities"
  add_foreign_key "auction_activity_participations", "orders", column: "auction_order_id"
  add_foreign_key "auction_activity_participations", "stores"
  add_foreign_key "auction_activity_participations", "users"
  add_foreign_key "auction_automatic_bids", "auction_activities"
  add_foreign_key "auction_automatic_bids", "users"
  add_foreign_key "auction_bids", "auction_activities"
  add_foreign_key "auction_bids", "members"
  add_foreign_key "auction_bids", "users"
  add_foreign_key "cities", "provinces"
  add_foreign_key "counties", "cities"
  add_foreign_key "custom_pages", "admin_users", column: "creator_id"
  add_foreign_key "event_form_records", "users"
  add_foreign_key "hot_searches", "stores"
  add_foreign_key "integral_records", "members"
  add_foreign_key "invoices", "users"
  add_foreign_key "item_nutrition_values", "items"
  add_foreign_key "item_nutrition_values", "nutritions"
  add_foreign_key "items", "qa_and_guarantees"
  add_foreign_key "live_room_lotteries", "live_rooms"
  add_foreign_key "live_room_lottery_winning_users", "live_room_lotteries"
  add_foreign_key "live_room_lottery_winning_users", "live_rooms"
  add_foreign_key "live_room_lottery_winning_users", "users"
  add_foreign_key "live_room_orders", "live_rooms"
  add_foreign_key "live_room_orders", "orders"
  add_foreign_key "live_room_orders", "users"
  add_foreign_key "live_room_subscriptions", "live_rooms"
  add_foreign_key "live_room_subscriptions", "users"
  add_foreign_key "live_room_viewed_user_stats", "live_rooms"
  add_foreign_key "live_room_viewed_users", "live_rooms"
  add_foreign_key "live_room_viewed_users", "users"
  add_foreign_key "live_rooms", "coupon_packages"
  add_foreign_key "live_rooms", "live_room_lotteries", column: "current_lottery_id"
  add_foreign_key "live_rooms", "stock_keeping_units", column: "highlighted_sku_id"
  add_foreign_key "members", "users"
  add_foreign_key "message_unread_counters", "users"
  add_foreign_key "mobile_blacklists", "users"
  add_foreign_key "multi_lang_configs", "stores"
  add_foreign_key "order_invoices", "orders"
  add_foreign_key "orders", "gift_card_coupons"
  add_foreign_key "orders", "groupons"
  add_foreign_key "orders", "promo_codes"
  add_foreign_key "orders", "provinces"
  add_foreign_key "orders", "self_pick_ups"
  add_foreign_key "orders", "warehouse_orders"
  add_foreign_key "push_message_read_logs", "push_messages"
  add_foreign_key "push_message_read_logs", "users"
  add_foreign_key "push_messages", "admin_users"
  add_foreign_key "push_messages", "stores"
  add_foreign_key "random_reduction_coupon_template_rules", "coupon_templates"
  add_foreign_key "sku_in_stock_notices", "stock_keeping_units"
  add_foreign_key "sku_in_stock_notices", "users"
  add_foreign_key "time_limited_promotion_prices", "stock_keeping_units"
  add_foreign_key "time_limited_promotion_prices", "time_limited_promotions"
  add_foreign_key "time_limited_promotions", "stores"
  add_foreign_key "users", "stores", column: "selected_store_id"
  add_foreign_key "users_push_messages", "push_messages"
  add_foreign_key "users_push_messages", "users"
  add_foreign_key "warehouse_orders", "stores"
  add_foreign_key "warehouse_orders", "users"
  add_foreign_key "web_banner_items", "web_banners"
  add_foreign_key "web_banners", "stores"
  add_foreign_key "web_custom_list_items", "items"
  add_foreign_key "web_custom_list_items", "web_custom_lists"
  add_foreign_key "web_custom_lists", "stores"
end
