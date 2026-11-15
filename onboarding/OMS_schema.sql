/*
 Navicat Premium Data Transfer

 Source Server         : eBest OMS 生產環境 (AWS)
 Source Server Type    : PostgreSQL
 Source Server Version : 170009 (170009)
 Source Host           : ebestprd.cvmog2guevqo.ap-southeast-2.rds.amazonaws.com:5432
 Source Catalog        : ebest_production
 Source Schema         : public

 Target Server Type    : PostgreSQL
 Target Server Version : 170009 (170009)
 File Encoding         : 65001

 Date: 11/11/2026 21:22:23
*/


-- ----------------------------
-- Table structure for actions
-- ----------------------------
CREATE TABLE "actions" (
  "id" int8 NOT NULL DEFAULT nextval('actions_id_seq'::regclass),
  "action_type" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "action_option" varchar COLLATE "pg_catalog"."default",
  "target_type" varchar COLLATE "pg_catalog"."default",
  "target_id" int4,
  "user_type" varchar COLLATE "pg_catalog"."default",
  "user_id" int4,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for addresses
-- ----------------------------
CREATE TABLE "addresses" (
  "id" int8 NOT NULL DEFAULT nextval('addresses_id_seq'::regclass),
  "detail_info" varchar COLLATE "pg_catalog"."default",
  "tel_number" varchar COLLATE "pg_catalog"."default",
  "first_name" varchar COLLATE "pg_catalog"."default",
  "postal_code" varchar COLLATE "pg_catalog"."default",
  "is_default" bool DEFAULT false,
  "user_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "google_place_id" varchar COLLATE "pg_catalog"."default",
  "province_name" varchar COLLATE "pg_catalog"."default",
  "city_name" varchar COLLATE "pg_catalog"."default",
  "email" varchar COLLATE "pg_catalog"."default",
  "street" varchar COLLATE "pg_catalog"."default",
  "street_number" varchar COLLATE "pg_catalog"."default",
  "company_name" varchar COLLATE "pg_catalog"."default",
  "alias_name" varchar COLLATE "pg_catalog"."default",
  "last_name" varchar COLLATE "pg_catalog"."default",
  "unit_number" varchar COLLATE "pg_catalog"."default",
  "remark" varchar COLLATE "pg_catalog"."default",
  "housing_type" int4
)
;
COMMENT ON COLUMN "addresses"."alias_name" IS '地址信息名称';
COMMENT ON COLUMN "addresses"."remark" IS '备注';

-- ----------------------------
-- Table structure for admin_assign_integral_records
-- ----------------------------
CREATE TABLE "admin_assign_integral_records" (
  "id" int8 NOT NULL DEFAULT nextval('admin_assign_integral_records_id_seq'::regclass),
  "admin_user_id" int8,
  "member_id" int8,
  "store_id" int8,
  "content" text COLLATE "pg_catalog"."default",
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for admin_user_stores
-- ----------------------------
CREATE TABLE "admin_user_stores" (
  "id" int8 NOT NULL DEFAULT nextval('admin_user_stores_id_seq'::regclass),
  "store_id" int8,
  "admin_user_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for admin_users
-- ----------------------------
CREATE TABLE "admin_users" (
  "id" int8 NOT NULL DEFAULT nextval('admin_users_id_seq'::regclass),
  "name" varchar COLLATE "pg_catalog"."default",
  "mobile" varchar COLLATE "pg_catalog"."default",
  "state" int4 DEFAULT 1,
  "role" int4 DEFAULT 1,
  "creator_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "email" varchar COLLATE "pg_catalog"."default",
  "password_digest" varchar COLLATE "pg_catalog"."default",
  "receive_notify_email" bool DEFAULT false,
  "permissions" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "can_read_category_ids" int4[] DEFAULT '{}'::integer[],
  "role_template_id" int8,
  "failed_attempts" int4 DEFAULT 0,
  "locked_at" timestamp(6)
)
;

-- ----------------------------
-- Table structure for ae_categories
-- ----------------------------
CREATE TABLE "ae_categories" (
  "id" int8 NOT NULL DEFAULT nextval('ae_categories_id_seq'::regclass),
  "name" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "ae_id" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "product_required_attributes" jsonb,
  "sku_attributes" jsonb,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for ae_drop_shipper_orders
-- ----------------------------
CREATE TABLE "ae_drop_shipper_orders" (
  "id" int8 NOT NULL DEFAULT nextval('ae_drop_shipper_orders_id_seq'::regclass),
  "order_id" int8,
  "ae_order_no" varchar COLLATE "pg_catalog"."default",
  "order_paidtime" varchar COLLATE "pg_catalog"."default",
  "gmt_create" varchar COLLATE "pg_catalog"."default",
  "order_status" varchar COLLATE "pg_catalog"."default",
  "logistics_status" varchar COLLATE "pg_catalog"."default",
  "order_amount" numeric(12,2),
  "child_order_list" jsonb DEFAULT '[]'::jsonb,
  "store_info" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;
COMMENT ON COLUMN "ae_drop_shipper_orders"."gmt_create" IS 'AE订单创建时间';
COMMENT ON COLUMN "ae_drop_shipper_orders"."order_amount" IS '订单总金额, 单位: AUD';
COMMENT ON COLUMN "ae_drop_shipper_orders"."child_order_list" IS '订单项信息';
COMMENT ON COLUMN "ae_drop_shipper_orders"."store_info" IS 'AE店铺信息';

-- ----------------------------
-- Table structure for after_sales
-- ----------------------------
CREATE TABLE "after_sales" (
  "id" int8 NOT NULL DEFAULT nextval('after_sales_id_seq'::regclass),
  "refund_no" varchar COLLATE "pg_catalog"."default",
  "after_sale_type" int4 DEFAULT 1,
  "status" int4 DEFAULT 1,
  "agreed_at" timestamp(6),
  "reason" varchar COLLATE "pg_catalog"."default",
  "amount_in_cent" int4,
  "user_id" int8,
  "order_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "logistic_no" varchar COLLATE "pg_catalog"."default",
  "logistic_company" varchar COLLATE "pg_catalog"."default",
  "total_quantity" int4 NOT NULL DEFAULT 0,
  "images" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "seller_reply" varchar COLLATE "pg_catalog"."default",
  "return_no" varchar COLLATE "pg_catalog"."default",
  "due_time" timestamp(6),
  "return_integral_amount" int4 DEFAULT 0,
  "original_amount_in_cent" int4,
  "channel" int4,
  "payment_type" varchar COLLATE "pg_catalog"."default",
  "applicant_type" int4 DEFAULT 1,
  "store_id" int8,
  "return_gift_card_amount_in_cent" int4 DEFAULT 0,
  "return_coupon_amount_in_cent" int4 DEFAULT 0,
  "return_type" int4 DEFAULT 1,
  "internal_reason" varchar COLLATE "pg_catalog"."default",
  "department" varchar COLLATE "pg_catalog"."default",
  "audit_explain" text COLLATE "pg_catalog"."default",
  "audit_images" varchar[] COLLATE "pg_catalog"."default",
  "audit_video" varchar COLLATE "pg_catalog"."default",
  "additional_information" varchar COLLATE "pg_catalog"."default",
  "is_real_claim" bool DEFAULT false,
  "lastest_operator_id" int8
)
;
COMMENT ON COLUMN "after_sales"."after_sale_type" IS '1 退款 2 退貨退款';
COMMENT ON COLUMN "after_sales"."return_no" IS 'erp退换货单号';
COMMENT ON COLUMN "after_sales"."applicant_type" IS '申请人类型';
COMMENT ON COLUMN "after_sales"."internal_reason" IS '内部原因';
COMMENT ON COLUMN "after_sales"."department" IS '责任部门';
COMMENT ON COLUMN "after_sales"."audit_explain" IS '审核说明';
COMMENT ON COLUMN "after_sales"."audit_images" IS '审核图片';
COMMENT ON COLUMN "after_sales"."audit_video" IS '审核视频';
COMMENT ON COLUMN "after_sales"."additional_information" IS '补充说明';
COMMENT ON COLUMN "after_sales"."is_real_claim" IS '是否真实理赔';

-- ----------------------------
-- Table structure for after_sales_order_items
-- ----------------------------
CREATE TABLE "after_sales_order_items" (
  "id" int8 NOT NULL DEFAULT nextval('after_sales_order_items_id_seq'::regclass),
  "order_item_id" int8,
  "after_sale_id" int8,
  "quantity" int4 NOT NULL DEFAULT 1,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "real_amount_in_cent" int4 DEFAULT 0,
  "cash_amount_in_cent" int4 DEFAULT 0,
  "service_amount_in_cent" int4 DEFAULT 0,
  "cost_integral" int4 DEFAULT 0,
  "gift_card_amount_in_cent" int4 DEFAULT 0,
  "contain_remainder" bool DEFAULT false,
  "max_service_amount_in_cent" int4 DEFAULT 0,
  "max_cost_integral" int4 DEFAULT 0,
  "max_gift_card_amount_in_cent" int4 DEFAULT 0,
  "max_cash_amount_in_cent" int4 DEFAULT 0,
  "original_real_amount_in_cent" int4 DEFAULT 0,
  "ae_gst_amount_in_cent" int4 DEFAULT 0,
  "max_ae_gst_amount_in_cent" int4 DEFAULT 0
)
;
COMMENT ON COLUMN "after_sales_order_items"."cash_amount_in_cent" IS '实际退款现金($)';
COMMENT ON COLUMN "after_sales_order_items"."service_amount_in_cent" IS '实际手续费($)';
COMMENT ON COLUMN "after_sales_order_items"."cost_integral" IS '实际金币数量';
COMMENT ON COLUMN "after_sales_order_items"."gift_card_amount_in_cent" IS '实际礼品卡($)';
COMMENT ON COLUMN "after_sales_order_items"."contain_remainder" IS '退款各项金额是否包含余数';
COMMENT ON COLUMN "after_sales_order_items"."original_real_amount_in_cent" IS '最初的优惠金额';

-- ----------------------------
-- Table structure for age_verification_translations
-- ----------------------------
CREATE TABLE "age_verification_translations" (
  "id" int8 NOT NULL DEFAULT nextval('age_verification_translations_id_seq'::regclass),
  "age_verification_id" int8 NOT NULL,
  "locale" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "title" varchar COLLATE "pg_catalog"."default",
  "content" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for age_verifications
-- ----------------------------
CREATE TABLE "age_verifications" (
  "id" int8 NOT NULL DEFAULT nextval('age_verifications_id_seq'::regclass),
  "parent_category_id" int8,
  "image" varchar COLLATE "pg_catalog"."default",
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "parent_web_category_id" int8
)
;

-- ----------------------------
-- Table structure for app_download_channels
-- ----------------------------
CREATE TABLE "app_download_channels" (
  "id" int8 NOT NULL DEFAULT nextval('app_download_channels_id_seq'::regclass),
  "code" varchar COLLATE "pg_catalog"."default",
  "name" varchar COLLATE "pg_catalog"."default",
  "qrcode" varchar COLLATE "pg_catalog"."default",
  "ios_views_count" int4 DEFAULT 0,
  "android_views_count" int4 DEFAULT 0,
  "other_views_count" int4 DEFAULT 0,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for app_text_messages
-- ----------------------------
CREATE TABLE "app_text_messages" (
  "id" int8 NOT NULL DEFAULT nextval('app_text_messages_id_seq'::regclass),
  "title" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "content" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "read_at" timestamp(6),
  "kind" int4 NOT NULL,
  "user_id" int8,
  "admin_user_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "target_type" varchar COLLATE "pg_catalog"."default",
  "target_id" int8
)
;

-- ----------------------------
-- Table structure for ar_internal_metadata
-- ----------------------------
CREATE TABLE "ar_internal_metadata" (
  "key" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "value" varchar COLLATE "pg_catalog"."default",
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for au_suburb_freight_templates
-- ----------------------------
CREATE TABLE "au_suburb_freight_templates" (
  "id" int8 NOT NULL DEFAULT nextval('au_suburb_freight_templates_id_seq'::regclass),
  "au_suburb_id" int8,
  "freight_template_id" int8
)
;

-- ----------------------------
-- Table structure for au_suburbs
-- ----------------------------
CREATE TABLE "au_suburbs" (
  "id" int8 NOT NULL DEFAULT nextval('au_suburbs_id_seq'::regclass),
  "name" varchar COLLATE "pg_catalog"."default",
  "state_name" varchar COLLATE "pg_catalog"."default",
  "state_short_name" varchar COLLATE "pg_catalog"."default",
  "postal_code" varchar COLLATE "pg_catalog"."default",
  "latitude" float8,
  "longitude" float8,
  "store_id" int8
)
;

-- ----------------------------
-- Table structure for auction_activities
-- ----------------------------
CREATE TABLE "auction_activities" (
  "id" int8 NOT NULL DEFAULT nextval('auction_activities_id_seq'::regclass),
  "cover" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "start_at" timestamp(6) NOT NULL,
  "default_end_at" timestamp(6) NOT NULL,
  "auto_renewal_end_at" bool NOT NULL DEFAULT false,
  "final_end_at" timestamp(6),
  "publish_at" timestamp(6),
  "state" int4 NOT NULL DEFAULT 0,
  "starting_price_in_cent" int4 NOT NULL,
  "bidding_increments_in_cent" int4 NOT NULL,
  "reserve_price_in_cent" int4,
  "directly_purchase_price_in_cent" int4,
  "detail_images" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "main_images" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "category_id" int8,
  "parent_category_id" int8,
  "minor_category_id" int8,
  "minor_parent_category_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "store_id" int8,
  "best_bid_id" int8,
  "best_bid_amount_in_cent" int4,
  "bids_count" int4 DEFAULT 0,
  "automatic_bids_count" int4 DEFAULT 0,
  "best_automatic_bid_id" int8,
  "item_id" int8,
  "stock_keeping_unit_id" int8,
  "no" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "order_id" int8,
  "brand_id" int8,
  "qa_and_guarantee_id" int8
)
;
COMMENT ON COLUMN "auction_activities"."starting_price_in_cent" IS '起拍价';
COMMENT ON COLUMN "auction_activities"."bidding_increments_in_cent" IS '出价最小增额';
COMMENT ON COLUMN "auction_activities"."reserve_price_in_cent" IS '底价';
COMMENT ON COLUMN "auction_activities"."directly_purchase_price_in_cent" IS '直接购买价';
COMMENT ON COLUMN "auction_activities"."detail_images" IS '主图';
COMMENT ON COLUMN "auction_activities"."main_images" IS '详情图';

-- ----------------------------
-- Table structure for auction_activity_participations
-- ----------------------------
CREATE TABLE "auction_activity_participations" (
  "id" int8 NOT NULL DEFAULT nextval('auction_activity_participations_id_seq'::regclass),
  "user_id" int8,
  "auction_activity_id" int8,
  "state" int4 NOT NULL DEFAULT 2,
  "auction_order_id" int8,
  "store_id" int8,
  "amount_in_cent" int4,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for auction_activity_translations
-- ----------------------------
CREATE TABLE "auction_activity_translations" (
  "id" int8 NOT NULL DEFAULT nextval('auction_activity_translations_id_seq'::regclass),
  "auction_activity_id" int8 NOT NULL,
  "locale" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "title" varchar COLLATE "pg_catalog"."default",
  "description" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for auction_automatic_bids
-- ----------------------------
CREATE TABLE "auction_automatic_bids" (
  "id" int8 NOT NULL DEFAULT nextval('auction_automatic_bids_id_seq'::regclass),
  "user_id" int8,
  "auction_activity_id" int8,
  "amount_limit_in_cent" int4 NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for auction_bids
-- ----------------------------
CREATE TABLE "auction_bids" (
  "id" int8 NOT NULL DEFAULT nextval('auction_bids_id_seq'::regclass),
  "kind" int4 NOT NULL DEFAULT 0,
  "user_id" int8,
  "auction_activity_id" int8,
  "member_id" int8,
  "amount_in_cent" int4 NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for banner_clicks
-- ----------------------------
CREATE TABLE "banner_clicks" (
  "id" int8 NOT NULL DEFAULT nextval('banner_clicks_id_seq'::regclass),
  "date" date,
  "url" varchar(2048) COLLATE "pg_catalog"."default",
  "count" int4 DEFAULT 0,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for brand_translations
-- ----------------------------
CREATE TABLE "brand_translations" (
  "id" int8 NOT NULL DEFAULT nextval('brand_translations_id_seq'::regclass),
  "brand_id" int8 NOT NULL,
  "locale" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "name" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for brands
-- ----------------------------
CREATE TABLE "brands" (
  "id" int8 NOT NULL DEFAULT nextval('brands_id_seq'::regclass),
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "cover" varchar COLLATE "pg_catalog"."default",
  "position" int4 NOT NULL DEFAULT 999999,
  "aws_lambda_image_generated" bool DEFAULT false
)
;

-- ----------------------------
-- Table structure for categories
-- ----------------------------
CREATE TABLE "categories" (
  "id" int8 NOT NULL DEFAULT nextval('categories_id_seq'::regclass),
  "parent_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "status" int4 DEFAULT 1,
  "position" int4 DEFAULT 0,
  "icon" varchar COLLATE "pg_catalog"."default",
  "bg_color" varchar COLLATE "pg_catalog"."default",
  "display_length" int4 DEFAULT 5,
  "filter_icon" varchar COLLATE "pg_catalog"."default",
  "can_create_invoice" bool DEFAULT true,
  "sort_item_ids" int4[] DEFAULT '{}'::integer[],
  "item_position" int4 DEFAULT 99999999,
  "need_age_verification" bool DEFAULT false,
  "show_on_web" bool DEFAULT false,
  "goto_kind" int4 NOT NULL DEFAULT 1,
  "search_keywords" text COLLATE "pg_catalog"."default",
  "external_url" varchar COLLATE "pg_catalog"."default",
  "aws_lambda_image_generated" bool DEFAULT false,
  "ae_drop_shipper" bool DEFAULT false,
  "ae_drop_shipper_category_id" varchar COLLATE "pg_catalog"."default"
)
;
COMMENT ON COLUMN "categories"."search_keywords" IS '搜索关键词, 用于提升搜索商品准确度';

-- ----------------------------
-- Table structure for category_translations
-- ----------------------------
CREATE TABLE "category_translations" (
  "id" int8 NOT NULL DEFAULT nextval('category_translations_id_seq'::regclass),
  "category_id" int8 NOT NULL,
  "locale" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "name" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for cities
-- ----------------------------
CREATE TABLE "cities" (
  "id" int8 NOT NULL DEFAULT nextval('cities_id_seq'::regclass),
  "name" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "province_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "kind" int4 DEFAULT 1,
  "code" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for comments
-- ----------------------------
CREATE TABLE "comments" (
  "id" int8 NOT NULL DEFAULT nextval('comments_id_seq'::regclass),
  "content" varchar COLLATE "pg_catalog"."default",
  "pictures" varchar[] COLLATE "pg_catalog"."default",
  "commentable_type" varchar COLLATE "pg_catalog"."default",
  "commentable_id" int4,
  "user_id" int8,
  "item_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "images" text[] COLLATE "pg_catalog"."default" DEFAULT '{}'::text[],
  "status" int4 DEFAULT 1,
  "deleted_at" timestamp(6),
  "is_top" bool DEFAULT false,
  "user_nickname" varchar COLLATE "pg_catalog"."default",
  "user_avatar" varchar COLLATE "pg_catalog"."default",
  "stock_keeping_unit_id" int4,
  "properties_text" varchar COLLATE "pg_catalog"."default",
  "parent_id" int4,
  "likes_count" int4 DEFAULT 0,
  "stars" int4 DEFAULT 5
)
;
COMMENT ON COLUMN "comments"."stars" IS '星级评分， 默认5分';

-- ----------------------------
-- Table structure for counties
-- ----------------------------
CREATE TABLE "counties" (
  "id" int8 NOT NULL DEFAULT nextval('counties_id_seq'::regclass),
  "name" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "city_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "kind" int4 DEFAULT 1,
  "code" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for coupon_auto_assignments
-- ----------------------------
CREATE TABLE "coupon_auto_assignments" (
  "id" int8 NOT NULL DEFAULT nextval('coupon_auto_assignments_id_seq'::regclass),
  "start_date" date,
  "end_date" date,
  "last_assigned_at" timestamp(6),
  "assign_type" int4 DEFAULT 0,
  "assign_user_ids" int4[] DEFAULT '{}'::integer[],
  "coupon_template_ids" int4[] DEFAULT '{}'::integer[],
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "deleted_at" timestamp(6)
)
;

-- ----------------------------
-- Table structure for coupon_packages
-- ----------------------------
CREATE TABLE "coupon_packages" (
  "id" int8 NOT NULL DEFAULT nextval('coupon_packages_id_seq'::regclass),
  "name" varchar COLLATE "pg_catalog"."default",
  "code" varchar COLLATE "pg_catalog"."default",
  "status" int4 DEFAULT 1,
  "user_kind" int4 DEFAULT 1,
  "coupon_template_ids" int4[] DEFAULT '{}'::integer[],
  "cover" varchar COLLATE "pg_catalog"."default",
  "start_at" timestamp(6) DEFAULT '-infinity'::timestamp without time zone,
  "end_at" timestamp(6) DEFAULT 'infinity'::timestamp without time zone,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "store_id" int8
)
;

-- ----------------------------
-- Table structure for coupon_packages_users
-- ----------------------------
CREATE TABLE "coupon_packages_users" (
  "coupon_package_id" int4,
  "user_id" int4
)
;

-- ----------------------------
-- Table structure for coupon_template_translations
-- ----------------------------
CREATE TABLE "coupon_template_translations" (
  "id" int8 NOT NULL DEFAULT nextval('coupon_template_translations_id_seq'::regclass),
  "coupon_template_id" int8 NOT NULL,
  "locale" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "title" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for coupon_templates
-- ----------------------------
CREATE TABLE "coupon_templates" (
  "id" int8 NOT NULL DEFAULT nextval('coupon_templates_id_seq'::regclass),
  "desc" varchar COLLATE "pg_catalog"."default",
  "kind" int4 DEFAULT 1,
  "denominations_in_cent" int4,
  "discount" float8,
  "at_least_amount_in_cent" int4,
  "need_at_least_amount" bool DEFAULT false,
  "time_kind" int4 DEFAULT 1,
  "time_limit_in_day" int4 DEFAULT 0,
  "start_at" timestamp(6),
  "end_at" timestamp(6),
  "details_image" varchar COLLATE "pg_catalog"."default",
  "expired_image" varchar COLLATE "pg_catalog"."default",
  "ticket_image" varchar COLLATE "pg_catalog"."default",
  "enabled" bool DEFAULT true,
  "remarks" varchar COLLATE "pg_catalog"."default",
  "code" varchar COLLATE "pg_catalog"."default",
  "users_count" int4 DEFAULT 0,
  "orders_count" int4 DEFAULT 0,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "item_ids" int4[] DEFAULT '{}'::integer[],
  "user_kind" int4,
  "qrcode" varchar COLLATE "pg_catalog"."default",
  "target_kind" int4 DEFAULT 1,
  "channel" int4 DEFAULT 1,
  "store_id" int8,
  "category_ids" int4[] DEFAULT '{}'::integer[],
  "coupons_count" int4 DEFAULT 0,
  "brand_ids" int4[] DEFAULT '{}'::integer[],
  "sub_category_ids" int4[] DEFAULT '{}'::integer[],
  "is_aus_qrcode" bool DEFAULT false,
  "delivery_types" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "payment_types" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "party" int4 DEFAULT 1,
  "min_denominations_in_cent" int4,
  "max_denominations_in_cent" int4,
  "display_in_item_detail" bool DEFAULT false,
  "usage_kind" int4,
  "assign_start_at" timestamp(6),
  "assign_end_at" timestamp(6),
  "assign_total_quantity" int4 DEFAULT 0,
  "custom_list_ids" int4[] DEFAULT '{}'::integer[],
  "max_random_reduction_count" int4 NOT NULL DEFAULT 0,
  "cost_accounting" int4
)
;
COMMENT ON COLUMN "coupon_templates"."desc" IS '使用说明';
COMMENT ON COLUMN "coupon_templates"."denominations_in_cent" IS '面额（单位：分）';
COMMENT ON COLUMN "coupon_templates"."at_least_amount_in_cent" IS '订单满减金额';
COMMENT ON COLUMN "coupon_templates"."need_at_least_amount" IS '是否有门槛使用';
COMMENT ON COLUMN "coupon_templates"."time_kind" IS '用券时间类型';
COMMENT ON COLUMN "coupon_templates"."time_limit_in_day" IS ' 领取后限时使用 0 表示无限';
COMMENT ON COLUMN "coupon_templates"."start_at" IS '开始时间（可以开始使用优惠券）';
COMMENT ON COLUMN "coupon_templates"."end_at" IS '结束时间（不能再使用优惠券）';
COMMENT ON COLUMN "coupon_templates"."enabled" IS '是否启用优惠券';
COMMENT ON COLUMN "coupon_templates"."code" IS '优惠券码';
COMMENT ON COLUMN "coupon_templates"."party" IS '发券方';
COMMENT ON COLUMN "coupon_templates"."assign_start_at" IS '领取开始时间';
COMMENT ON COLUMN "coupon_templates"."assign_end_at" IS '领取结束时间';
COMMENT ON COLUMN "coupon_templates"."assign_total_quantity" IS '可领取总数量';
COMMENT ON COLUMN "coupon_templates"."cost_accounting" IS '成本核算, 1: 平台, 2: 板块';

-- ----------------------------
-- Table structure for coupons
-- ----------------------------
CREATE TABLE "coupons" (
  "id" int8 NOT NULL DEFAULT nextval('coupons_id_seq'::regclass),
  "title" varchar COLLATE "pg_catalog"."default",
  "desc" varchar COLLATE "pg_catalog"."default",
  "code" varchar COLLATE "pg_catalog"."default",
  "kind" int4 DEFAULT 1,
  "expired_at" timestamp(6),
  "start_at" timestamp(6),
  "preferences" json DEFAULT '{}'::json,
  "status" int4 DEFAULT 1,
  "coupon_template_id" int8,
  "user_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "time_kind" int4 DEFAULT 1,
  "item_ids" int4[] DEFAULT '{}'::integer[],
  "qrcode" varchar COLLATE "pg_catalog"."default",
  "target_kind" int4 DEFAULT 1,
  "channel" int4 DEFAULT 1,
  "assigned_at" timestamp(6),
  "used_at" timestamp(6),
  "store_id" int8,
  "coupon_type" int4 DEFAULT 1,
  "invitee_id" int8,
  "category_ids" int4[] DEFAULT '{}'::integer[],
  "brand_ids" int4[] DEFAULT '{}'::integer[],
  "sub_category_ids" int4[] DEFAULT '{}'::integer[],
  "is_aus_qrcode" bool DEFAULT false,
  "delivery_types" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "payment_types" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "party" int4 DEFAULT 1,
  "custom_list_ids" int4[] DEFAULT '{}'::integer[]
)
;
COMMENT ON COLUMN "coupons"."kind" IS '1 折扣 2 滿減';
COMMENT ON COLUMN "coupons"."status" IS '1 優惠中  2 已使用  3 已過期';
COMMENT ON COLUMN "coupons"."party" IS '发券方';

-- ----------------------------
-- Table structure for custom_list_items
-- ----------------------------
CREATE TABLE "custom_list_items" (
  "id" int8 NOT NULL DEFAULT nextval('custom_list_items_id_seq'::regclass),
  "position" int4,
  "item_id" int8,
  "custom_list_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "store_id" int8
)
;

-- ----------------------------
-- Table structure for custom_list_translations
-- ----------------------------
CREATE TABLE "custom_list_translations" (
  "id" int8 NOT NULL DEFAULT nextval('custom_list_translations_id_seq'::regclass),
  "custom_list_id" int8 NOT NULL,
  "locale" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "title" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for custom_lists
-- ----------------------------
CREATE TABLE "custom_lists" (
  "id" int8 NOT NULL DEFAULT nextval('custom_lists_id_seq'::regclass),
  "remark" varchar COLLATE "pg_catalog"."default",
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "as_category" bool DEFAULT false,
  "position" int4 DEFAULT 0,
  "store_id" int8,
  "icon" varchar COLLATE "pg_catalog"."default",
  "bg_color" varchar COLLATE "pg_catalog"."default" DEFAULT '#FEEDDC'::character varying,
  "show_discount_rate" bool DEFAULT false,
  "items_shuffled" bool DEFAULT false,
  "same_day_delivery" bool DEFAULT false,
  "kind" int4 DEFAULT 1,
  "parent_category_id" int4,
  "ae_drop_shipper" bool DEFAULT false
)
;
COMMENT ON COLUMN "custom_lists"."kind" IS '列表类型';

-- ----------------------------
-- Table structure for custom_pages
-- ----------------------------
CREATE TABLE "custom_pages" (
  "id" int8 NOT NULL DEFAULT nextval('custom_pages_id_seq'::regclass),
  "name" varchar COLLATE "pg_catalog"."default",
  "en_name" varchar COLLATE "pg_catalog"."default",
  "qrcode_url" varchar COLLATE "pg_catalog"."default",
  "components" json DEFAULT '[]'::json,
  "default" bool DEFAULT false,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "store_id" int8,
  "is_aus_qrcode" bool DEFAULT false,
  "bg_color" varchar COLLATE "pg_catalog"."default",
  "creator_id" int8,
  "collaborator_ids" int4[] DEFAULT '{}'::integer[]
)
;

-- ----------------------------
-- Table structure for cutoff_times
-- ----------------------------
CREATE TABLE "cutoff_times" (
  "id" int8 NOT NULL DEFAULT nextval('cutoff_times_id_seq'::regclass),
  "time_at" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "item_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "weekdays" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "deliver_after_n_days" int4 DEFAULT 2
)
;
COMMENT ON COLUMN "cutoff_times"."deliver_after_n_days" IS '默认接单后2天发货';

-- ----------------------------
-- Table structure for delivery_areas
-- ----------------------------
CREATE TABLE "delivery_areas" (
  "id" int8 NOT NULL DEFAULT nextval('delivery_areas_id_seq'::regclass),
  "suburb" varchar COLLATE "pg_catalog"."default",
  "postal_code" varchar COLLATE "pg_catalog"."default",
  "latitude" float8,
  "longitude" float8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "au_suburb_id" int4,
  "delivery_time_id" int8,
  "same_day_delivery_time_id" int8
)
;

-- ----------------------------
-- Table structure for delivery_time_order_date_analyses
-- ----------------------------
CREATE TABLE "delivery_time_order_date_analyses" (
  "id" int8 NOT NULL DEFAULT nextval('delivery_time_order_date_analyses_id_seq'::regclass),
  "delivery_time_id" int4,
  "delivery_date" date,
  "distinct_address_count" int4 DEFAULT 0,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for delivery_time_period_settings
-- ----------------------------
CREATE TABLE "delivery_time_period_settings" (
  "id" int8 NOT NULL DEFAULT nextval('delivery_time_period_settings_id_seq'::regclass),
  "delivery_time_period_id" int8,
  "prefer_time" varchar COLLATE "pg_catalog"."default",
  "order_address_limit_every_day" int4 DEFAULT 0,
  "freight_in_cent" int4 DEFAULT 0,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "delivery_time_id" int8
)
;
COMMENT ON COLUMN "delivery_time_period_settings"."order_address_limit_every_day" IS '订单地址数上限，不受限于系统设置的地址数配送上限';
COMMENT ON COLUMN "delivery_time_period_settings"."freight_in_cent" IS '运费，单位：分';

-- ----------------------------
-- Table structure for delivery_time_period_translations
-- ----------------------------
CREATE TABLE "delivery_time_period_translations" (
  "id" int8 NOT NULL DEFAULT nextval('delivery_time_period_translations_id_seq'::regclass),
  "delivery_time_period_id" int8 NOT NULL,
  "locale" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "title" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for delivery_time_periods
-- ----------------------------
CREATE TABLE "delivery_time_periods" (
  "id" int8 NOT NULL DEFAULT nextval('delivery_time_periods_id_seq'::regclass),
  "delivery_time_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for delivery_times
-- ----------------------------
CREATE TABLE "delivery_times" (
  "id" int8 NOT NULL DEFAULT nextval('delivery_times_id_seq'::regclass),
  "name" varchar COLLATE "pg_catalog"."default",
  "weekdays" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "time_period" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "limited_by_orders_limit_every_day" bool DEFAULT true,
  "specific_orders_limit_every_day" int4 DEFAULT 0,
  "specific_total_orders_limit_every_day" int4 DEFAULT 0
)
;
COMMENT ON COLUMN "delivery_times"."name" IS '名称';
COMMENT ON COLUMN "delivery_times"."specific_orders_limit_every_day" IS '特定订单上限，不受限于系统设置的地址数配送上限';
COMMENT ON COLUMN "delivery_times"."specific_total_orders_limit_every_day" IS '特定订单上限，不受限于系统设置的订单配送上限';

-- ----------------------------
-- Table structure for event_form_records
-- ----------------------------
CREATE TABLE "event_form_records" (
  "id" int8 NOT NULL DEFAULT nextval('event_form_records_id_seq'::regclass),
  "user_id" int8,
  "event_slug" varchar COLLATE "pg_catalog"."default",
  "data" json DEFAULT '{}'::json,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "event_page_id" int8,
  "completed_at" timestamp(6)
)
;

-- ----------------------------
-- Table structure for event_pages
-- ----------------------------
CREATE TABLE "event_pages" (
  "id" int8 NOT NULL DEFAULT nextval('event_pages_id_seq'::regclass),
  "slug" varchar COLLATE "pg_catalog"."default",
  "name" varchar COLLATE "pg_catalog"."default",
  "event_form_records_count" int4,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for external_links
-- ----------------------------
CREATE TABLE "external_links" (
  "id" int8 NOT NULL DEFAULT nextval('external_links_id_seq'::regclass),
  "name" varchar COLLATE "pg_catalog"."default",
  "link" varchar COLLATE "pg_catalog"."default",
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for external_mini_programs
-- ----------------------------
CREATE TABLE "external_mini_programs" (
  "id" int8 NOT NULL DEFAULT nextval('external_mini_programs_id_seq'::regclass),
  "name" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "origin_id" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "path" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "app_id" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "env_version" int4 NOT NULL DEFAULT 0,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;
COMMENT ON COLUMN "external_mini_programs"."env_version" IS '小程序版本：0 release 正式版, 1 develop 开发版, 2 trial 体验版';

-- ----------------------------
-- Table structure for extra_orders_limits
-- ----------------------------
CREATE TABLE "extra_orders_limits" (
  "id" int8 NOT NULL DEFAULT nextval('extra_orders_limits_id_seq'::regclass),
  "order_amount_in_cent" int4 NOT NULL,
  "delivery_date" date NOT NULL,
  "begin_at" timestamp(6) NOT NULL,
  "extra_merchant_delivery_orders_limit" int4 NOT NULL DEFAULT 0,
  "store_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "extra_merchant_delivery_total_orders_limit" int4 DEFAULT 0
)
;
COMMENT ON COLUMN "extra_orders_limits"."extra_merchant_delivery_orders_limit" IS '额外地址数配送上限';
COMMENT ON COLUMN "extra_orders_limits"."extra_merchant_delivery_total_orders_limit" IS '额外订单配送上限';

-- ----------------------------
-- Table structure for form_item_applications
-- ----------------------------
CREATE TABLE "form_item_applications" (
  "id" int8 NOT NULL DEFAULT nextval('form_item_applications_id_seq'::regclass),
  "form_item_id" int8,
  "user_id" int8,
  "store_id" int8,
  "channel" int4,
  "apply_properties" "public"."hstore",
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;
COMMENT ON COLUMN "form_item_applications"."apply_properties" IS '申请信息';

-- ----------------------------
-- Table structure for form_item_translations
-- ----------------------------
CREATE TABLE "form_item_translations" (
  "id" int8 NOT NULL DEFAULT nextval('form_item_translations_id_seq'::regclass),
  "form_item_id" int8 NOT NULL,
  "locale" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "title" varchar COLLATE "pg_catalog"."default",
  "description" text COLLATE "pg_catalog"."default",
  "name_placeholder" varchar COLLATE "pg_catalog"."default",
  "mobile_placeholder" varchar COLLATE "pg_catalog"."default",
  "email_placeholder" varchar COLLATE "pg_catalog"."default",
  "birthday_placeholder" varchar COLLATE "pg_catalog"."default",
  "address_placeholder" varchar COLLATE "pg_catalog"."default",
  "remark_placeholder" varchar COLLATE "pg_catalog"."default"
)
;
COMMENT ON COLUMN "form_item_translations"."name_placeholder" IS '姓名占位符';
COMMENT ON COLUMN "form_item_translations"."mobile_placeholder" IS '手机号占位符';
COMMENT ON COLUMN "form_item_translations"."email_placeholder" IS '邮箱占位符';
COMMENT ON COLUMN "form_item_translations"."birthday_placeholder" IS '生日占位符';
COMMENT ON COLUMN "form_item_translations"."address_placeholder" IS '地址占位符';
COMMENT ON COLUMN "form_item_translations"."remark_placeholder" IS '备注占位符';

-- ----------------------------
-- Table structure for form_items
-- ----------------------------
CREATE TABLE "form_items" (
  "id" int8 NOT NULL DEFAULT nextval('form_items_id_seq'::regclass),
  "listing_type" int4,
  "category_id" int8,
  "parent_category_id" int4,
  "minor_category_id" int4,
  "cover" varchar COLLATE "pg_catalog"."default",
  "main_images" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "detail_images" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "form_options" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "notification_emails" varchar COLLATE "pg_catalog"."default",
  "translated_searchable_title" varchar COLLATE "pg_catalog"."default",
  "translated_searchable_description" varchar COLLATE "pg_catalog"."default",
  "store_id" int8,
  "channels" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;
COMMENT ON COLUMN "form_items"."notification_emails" IS '多个email用分号隔开';

-- ----------------------------
-- Table structure for freight_template_translations
-- ----------------------------
CREATE TABLE "freight_template_translations" (
  "id" int8 NOT NULL DEFAULT nextval('freight_template_translations_id_seq'::regclass),
  "freight_template_id" int8 NOT NULL,
  "locale" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "name" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for freight_templates
-- ----------------------------
CREATE TABLE "freight_templates" (
  "id" int8 NOT NULL DEFAULT nextval('freight_templates_id_seq'::regclass),
  "first_kg_charge_in_cent" int4 NOT NULL,
  "second_kg_charge_in_cent" int4 NOT NULL,
  "continued_weight_charge_in_cent" int4 NOT NULL,
  "extra_charge_in_cent" int4 NOT NULL DEFAULT 0,
  "type" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "freight_template_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "delivery_type" int4 DEFAULT 1,
  "free_shipping_amount_in_cent" int4,
  "first_kg_cost_in_cent" int4 DEFAULT 0,
  "second_kg_cost_in_cent" int4 DEFAULT 0,
  "continued_weight_cost_in_cent" int4 DEFAULT 0,
  "extra_cost_in_cent" int4 DEFAULT 0,
  "store_id" int8,
  "app_free_shipping_amount_in_cent" int4,
  "web_free_shipping_amount_in_cent" int4,
  "mini_program_free_shipping_amount_in_cent" int4,
  "ae_drop_shipper" bool DEFAULT false,
  "long_distance_fee_in_cent" int4 DEFAULT 0
)
;
COMMENT ON COLUMN "freight_templates"."first_kg_charge_in_cent" IS '1KG以内运费';
COMMENT ON COLUMN "freight_templates"."second_kg_charge_in_cent" IS '2KG以内运费';
COMMENT ON COLUMN "freight_templates"."continued_weight_charge_in_cent" IS '超过2KG后每KG运费，不足1KG按1KG算';
COMMENT ON COLUMN "freight_templates"."extra_charge_in_cent" IS '超过2KG后一次性的额外费用';
COMMENT ON COLUMN "freight_templates"."free_shipping_amount_in_cent" IS '满金额免运费';
COMMENT ON COLUMN "freight_templates"."first_kg_cost_in_cent" IS '1KG以内运费成本';
COMMENT ON COLUMN "freight_templates"."second_kg_cost_in_cent" IS '2KG以内运费成本';
COMMENT ON COLUMN "freight_templates"."continued_weight_cost_in_cent" IS '超过2KG后每KG运费成本，不足1KG按1KG算';
COMMENT ON COLUMN "freight_templates"."extra_cost_in_cent" IS '超过2KG后一次性的额外费用';
COMMENT ON COLUMN "freight_templates"."app_free_shipping_amount_in_cent" IS 'App满金额免运费';
COMMENT ON COLUMN "freight_templates"."web_free_shipping_amount_in_cent" IS 'Web满金额免运费';
COMMENT ON COLUMN "freight_templates"."mini_program_free_shipping_amount_in_cent" IS '小程序满金额免运费';
COMMENT ON COLUMN "freight_templates"."long_distance_fee_in_cent" IS '远程运费';

-- ----------------------------
-- Table structure for freight_templates_items
-- ----------------------------
CREATE TABLE "freight_templates_items" (
  "freight_template_id" int8,
  "item_id" int8
)
;

-- ----------------------------
-- Table structure for gift_activities
-- ----------------------------
CREATE TABLE "gift_activities" (
  "id" int8 NOT NULL DEFAULT nextval('gift_activities_id_seq'::regclass),
  "start_at" timestamp(6),
  "end_at" timestamp(6),
  "status" int4 DEFAULT 1,
  "rules" json,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "store_id" int8
)
;

-- ----------------------------
-- Table structure for gift_card_coupons
-- ----------------------------
CREATE TABLE "gift_card_coupons" (
  "id" int8 NOT NULL DEFAULT nextval('gift_card_coupons_id_seq'::regclass),
  "gift_card_template_id" int8,
  "code" varchar COLLATE "pg_catalog"."default",
  "denominations_in_cent" int4 DEFAULT 0,
  "used_amount_in_cent" int4 DEFAULT 0,
  "status" int4 DEFAULT 1,
  "expired_at" timestamp(6),
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "pin_code" varchar COLLATE "pg_catalog"."default",
  "store_ids" int4[] DEFAULT '{}'::integer[],
  "not_eligible_for_free_gift" bool DEFAULT true
)
;
COMMENT ON COLUMN "gift_card_coupons"."not_eligible_for_free_gift" IS '是否不参与满赠, 默认不参与';

-- ----------------------------
-- Table structure for gift_card_templates
-- ----------------------------
CREATE TABLE "gift_card_templates" (
  "id" int8 NOT NULL DEFAULT nextval('gift_card_templates_id_seq'::regclass),
  "denominations_in_cent" int4 DEFAULT 0,
  "quantity" int4 DEFAULT 0,
  "expired_at" timestamp(6),
  "purchaser" varchar COLLATE "pg_catalog"."default",
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "store_ids" int4[] DEFAULT '{}'::integer[],
  "purpose" int4 DEFAULT 1,
  "not_eligible_for_free_gift" bool DEFAULT true
)
;
COMMENT ON COLUMN "gift_card_templates"."not_eligible_for_free_gift" IS '是否不参与满赠, 默认不参与';

-- ----------------------------
-- Table structure for groupon_activities
-- ----------------------------
CREATE TABLE "groupon_activities" (
  "id" int8 NOT NULL DEFAULT nextval('groupon_activities_id_seq'::regclass),
  "kind" int4,
  "price_in_cent" int4,
  "user_count" int4,
  "start_at" timestamp(6),
  "end_at" timestamp(6),
  "enabled" bool,
  "item_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "is_real" bool DEFAULT false,
  "expired_hours" int4 DEFAULT 0,
  "store_id" int8,
  "type" varchar COLLATE "pg_catalog"."default" DEFAULT 'MagicBean::NormalGrouponActivity'::character varying,
  "wms_sync_type" int4 DEFAULT 1,
  "rules" text COLLATE "pg_catalog"."default"
)
;
COMMENT ON COLUMN "groupon_activities"."price_in_cent" IS '产品拼团价格';
COMMENT ON COLUMN "groupon_activities"."user_count" IS '拼团要求人数';

-- ----------------------------
-- Table structure for groupons
-- ----------------------------
CREATE TABLE "groupons" (
  "id" int8 NOT NULL DEFAULT nextval('groupons_id_seq'::regclass),
  "status" int4,
  "expired_at" timestamp(6),
  "finished_at" timestamp(6),
  "cancel_at" timestamp(6),
  "creator_id" int8,
  "groupon_activity_id" int8,
  "sku_groupon_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "channel" int4 DEFAULT 1,
  "store_id" int8
)
;

-- ----------------------------
-- Table structure for histories
-- ----------------------------
CREATE TABLE "histories" (
  "id" int8 NOT NULL DEFAULT nextval('histories_id_seq'::regclass),
  "operator_type" varchar COLLATE "pg_catalog"."default",
  "operator_id" int8,
  "operatable_type" varchar COLLATE "pg_catalog"."default",
  "operatable_id" int8,
  "action_type" int4 NOT NULL,
  "params" jsonb,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "page_type" int4 DEFAULT 1,
  "channel" int4 DEFAULT 1,
  "store_id" int8
)
;

-- ----------------------------
-- Table structure for homepage_paging_settings
-- ----------------------------
CREATE TABLE "homepage_paging_settings" (
  "id" int8 NOT NULL DEFAULT nextval('homepage_paging_settings_id_seq'::regclass),
  "name" varchar COLLATE "pg_catalog"."default",
  "image" varchar COLLATE "pg_catalog"."default",
  "custom_page_id" int8,
  "position" int4 DEFAULT 99,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "show_banners" bool DEFAULT true,
  "banners" jsonb DEFAULT '{}'::jsonb,
  "show_image_notice" bool DEFAULT true,
  "image_notice" jsonb DEFAULT '{}'::jsonb,
  "background_image" varchar COLLATE "pg_catalog"."default",
  "store_id" int8,
  "selected_image" varchar COLLATE "pg_catalog"."default"
)
;
COMMENT ON COLUMN "homepage_paging_settings"."selected_image" IS '选中图片';

-- ----------------------------
-- Table structure for hot_search_translations
-- ----------------------------
CREATE TABLE "hot_search_translations" (
  "id" int8 NOT NULL DEFAULT nextval('hot_search_translations_id_seq'::regclass),
  "hot_search_id" int8 NOT NULL,
  "locale" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "word" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for hot_searches
-- ----------------------------
CREATE TABLE "hot_searches" (
  "id" int8 NOT NULL DEFAULT nextval('hot_searches_id_seq'::regclass),
  "position" int4 NOT NULL,
  "store_id" int8,
  "show" bool DEFAULT false,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "channels" jsonb DEFAULT '[]'::jsonb,
  "ae_drop_shipper" bool DEFAULT false
)
;

-- ----------------------------
-- Table structure for hot_sell_configs
-- ----------------------------
CREATE TABLE "hot_sell_configs" (
  "id" int8 NOT NULL DEFAULT nextval('hot_sell_configs_id_seq'::regclass),
  "last_x_days" int4 DEFAULT 14,
  "show_item_nums" int4 DEFAULT 30,
  "contains_order_gift" bool DEFAULT true,
  "contains_order_pool_gift" bool DEFAULT true,
  "is_show_storage_on_sale" bool DEFAULT true,
  "enabled" bool DEFAULT true,
  "category_id" int8,
  "store_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "position" int4 DEFAULT 0
)
;
COMMENT ON COLUMN "hot_sell_configs"."last_x_days" IS '过去X天销量';
COMMENT ON COLUMN "hot_sell_configs"."show_item_nums" IS '最多展示几个商品';
COMMENT ON COLUMN "hot_sell_configs"."contains_order_gift" IS '销量包含全场满赠数量';
COMMENT ON COLUMN "hot_sell_configs"."contains_order_pool_gift" IS '销量包含优惠池满赠数量';
COMMENT ON COLUMN "hot_sell_configs"."is_show_storage_on_sale" IS '仅展示有库存开卖商品';
COMMENT ON COLUMN "hot_sell_configs"."enabled" IS '是否展示热卖榜';

-- ----------------------------
-- Table structure for integral_records
-- ----------------------------
CREATE TABLE "integral_records" (
  "id" int8 NOT NULL DEFAULT nextval('integral_records_id_seq'::regclass),
  "available_integral" int4,
  "blocked_integral" int4,
  "integral" int4,
  "kind" int4,
  "member_id" int8,
  "targetable_type" varchar COLLATE "pg_catalog"."default",
  "targetable_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "status" int4 DEFAULT 2,
  "channel" int4 DEFAULT 1
)
;

-- ----------------------------
-- Table structure for invoices
-- ----------------------------
CREATE TABLE "invoices" (
  "id" int8 NOT NULL DEFAULT nextval('invoices_id_seq'::regclass),
  "title" varchar COLLATE "pg_catalog"."default",
  "abn" varchar COLLATE "pg_catalog"."default",
  "first_name" varchar COLLATE "pg_catalog"."default",
  "last_name" varchar COLLATE "pg_catalog"."default",
  "tel_number" varchar COLLATE "pg_catalog"."default",
  "address" varchar COLLATE "pg_catalog"."default",
  "email" varchar COLLATE "pg_catalog"."default",
  "user_id" int8,
  "alias_name" varchar COLLATE "pg_catalog"."default",
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "is_default" bool DEFAULT false,
  "kind" int4 DEFAULT 1
)
;

-- ----------------------------
-- Table structure for item_banner_clicks
-- ----------------------------
CREATE TABLE "item_banner_clicks" (
  "id" int8 NOT NULL DEFAULT nextval('item_banner_clicks_id_seq'::regclass),
  "date" date,
  "count" int4 DEFAULT 0,
  "item_banner_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for item_banners
-- ----------------------------
CREATE TABLE "item_banners" (
  "id" int8 NOT NULL DEFAULT nextval('item_banners_id_seq'::regclass),
  "title" varchar COLLATE "pg_catalog"."default",
  "banner" varchar COLLATE "pg_catalog"."default",
  "item_ids" int4[] DEFAULT '{}'::integer[],
  "start_at" timestamp(6),
  "end_at" timestamp(6),
  "path" varchar COLLATE "pg_catalog"."default",
  "enabled" bool DEFAULT false,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;
COMMENT ON COLUMN "item_banners"."path" IS '跳转路径';

-- ----------------------------
-- Table structure for item_nutrition_values
-- ----------------------------
CREATE TABLE "item_nutrition_values" (
  "id" int8 NOT NULL DEFAULT nextval('item_nutrition_values_id_seq'::regclass),
  "item_id" int8,
  "nutrition_id" int8,
  "avg_qty_per_package" varchar COLLATE "pg_catalog"."default",
  "avg_qty_per_100_units" varchar COLLATE "pg_catalog"."default",
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for item_search_histories
-- ----------------------------
CREATE TABLE "item_search_histories" (
  "id" int8 NOT NULL DEFAULT nextval('item_search_histories_id_seq'::regclass),
  "word" varchar COLLATE "pg_catalog"."default",
  "search_date" date,
  "user_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "channel" int4 DEFAULT 2
)
;
COMMENT ON COLUMN "item_search_histories"."channel" IS '渠道, 默认app';

-- ----------------------------
-- Table structure for item_tag_group_translations
-- ----------------------------
CREATE TABLE "item_tag_group_translations" (
  "id" int8 NOT NULL DEFAULT nextval('item_tag_group_translations_id_seq'::regclass),
  "item_tag_group_id" int8 NOT NULL,
  "locale" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "name" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for item_tag_groups
-- ----------------------------
CREATE TABLE "item_tag_groups" (
  "id" int8 NOT NULL DEFAULT nextval('item_tag_groups_id_seq'::regclass),
  "item_tag_type_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for item_tag_relations
-- ----------------------------
CREATE TABLE "item_tag_relations" (
  "id" int8 NOT NULL DEFAULT nextval('item_tag_relations_id_seq'::regclass),
  "item_id" int8,
  "item_tag_id" int8,
  "allow_view_same_tag_items" bool DEFAULT false,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;
COMMENT ON COLUMN "item_tag_relations"."allow_view_same_tag_items" IS '是否允许查看同标签下的商品';

-- ----------------------------
-- Table structure for item_tag_translations
-- ----------------------------
CREATE TABLE "item_tag_translations" (
  "id" int8 NOT NULL DEFAULT nextval('item_tag_translations_id_seq'::regclass),
  "item_tag_id" int8 NOT NULL,
  "locale" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "name" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for item_tag_types
-- ----------------------------
CREATE TABLE "item_tag_types" (
  "id" int8 NOT NULL DEFAULT nextval('item_tag_types_id_seq'::regclass),
  "name" varchar COLLATE "pg_catalog"."default",
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;
COMMENT ON COLUMN "item_tag_types"."name" IS '类型名称';

-- ----------------------------
-- Table structure for item_tags
-- ----------------------------
CREATE TABLE "item_tags" (
  "id" int8 NOT NULL DEFAULT nextval('item_tags_id_seq'::regclass),
  "item_tag_group_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "item_tag_relations_count" int4 DEFAULT 0
)
;
COMMENT ON COLUMN "item_tags"."item_tag_relations_count" IS '打标签次数';

-- ----------------------------
-- Table structure for item_translations
-- ----------------------------
CREATE TABLE "item_translations" (
  "id" int8 NOT NULL DEFAULT nextval('item_translations_id_seq'::regclass),
  "item_id" int8 NOT NULL,
  "locale" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "title" varchar COLLATE "pg_catalog"."default",
  "description" text COLLATE "pg_catalog"."default",
  "shared_description" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for items
-- ----------------------------
CREATE TABLE "items" (
  "id" int8 NOT NULL DEFAULT nextval('items_id_seq'::regclass),
  "buy_quota" int4 DEFAULT 0,
  "no" varchar COLLATE "pg_catalog"."default",
  "price_in_cent" int4 DEFAULT 0,
  "item_type" int4 DEFAULT 1,
  "quantity" int4 NOT NULL DEFAULT 0,
  "listing_type" int4 DEFAULT 1,
  "start_selling_at" timestamp(6),
  "comments_count" int4 DEFAULT 0,
  "category_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "main_images" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "detail_images" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "likes_count" int4 DEFAULT 0,
  "likes_count_offset" int4 NOT NULL DEFAULT 0,
  "sales_count" int4 DEFAULT 0,
  "fixed_freight" int4 DEFAULT 0,
  "freight_type" int4 NOT NULL DEFAULT 1,
  "qa_and_guarantee_id" int8,
  "brand_id" int8,
  "monthly_sales_count_offset" int4 NOT NULL DEFAULT 0,
  "actual_monthly_sales_count" int4 NOT NULL DEFAULT 0,
  "qrcode" varchar COLLATE "pg_catalog"."default",
  "sub_title" varchar COLLATE "pg_catalog"."default",
  "cover" varchar COLLATE "pg_catalog"."default",
  "share_cover" varchar COLLATE "pg_catalog"."default",
  "position" int4 DEFAULT 99999999,
  "delivery_type" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "strikethrough_price_in_cent" int4,
  "buy_quota_days" int4 DEFAULT 0,
  "detail_video" varchar COLLATE "pg_catalog"."default",
  "fixed_freight_cost" int4 DEFAULT 0,
  "store_id" int8,
  "product_id" int8,
  "sales_count_offset" int4 DEFAULT 0,
  "display_sales_count" int4 DEFAULT 0,
  "minor_category_id" int4,
  "is_presell" bool DEFAULT false,
  "presell_dispatch_on" date,
  "presell_end_at" timestamp(6),
  "latest_presell_dispatch_on" date,
  "short_title" varchar COLLATE "pg_catalog"."default",
  "parent_category_id" int4,
  "top_left_corner_tag_image" varchar COLLATE "pg_catalog"."default",
  "is_virtual" bool DEFAULT false,
  "is_aus_qrcode" bool DEFAULT false,
  "coupon_enabled" bool DEFAULT true,
  "translated_searchable_title" varchar COLLATE "pg_catalog"."default",
  "translated_searchable_description" varchar COLLATE "pg_catalog"."default",
  "free_shipping" bool DEFAULT true,
  "storage_method" int4 DEFAULT 0,
  "production_place" varchar COLLATE "pg_catalog"."default",
  "allergen" varchar COLLATE "pg_catalog"."default",
  "serving_per_package" varchar COLLATE "pg_catalog"."default",
  "serving_size" varchar COLLATE "pg_catalog"."default",
  "new_user_price_in_cent" int4,
  "ingredient" varchar COLLATE "pg_catalog"."default",
  "delivery_weekdays" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "gift_card_enabled" bool DEFAULT true,
  "channels" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "expiration_date" date,
  "show_expiration_date" bool DEFAULT false,
  "days_ahead_to_show_expiration" int4,
  "web_category_id" int4,
  "parent_web_category_id" int4,
  "minor_web_category_id" int4,
  "batch_reindex_date" date,
  "not_eligible_for_free_gift" bool DEFAULT false,
  "first_sale_at" timestamp(6),
  "leader" varchar COLLATE "pg_catalog"."default" DEFAULT '其他'::character varying,
  "gift_only" bool DEFAULT false,
  "deleted_at" timestamp(6),
  "ae_category_id" varchar COLLATE "pg_catalog"."default",
  "ae_product_attributes" jsonb,
  "ae_freight_info" jsonb,
  "aws_lambda_image_generated" bool DEFAULT false,
  "ae_drop_shipper" bool DEFAULT false,
  "ae_h5_description" text COLLATE "pg_catalog"."default",
  "is_ae_choice" bool,
  "ae_delivery_date_desc" varchar COLLATE "pg_catalog"."default",
  "ae_delivery_date" varchar COLLATE "pg_catalog"."default",
  "ae_estimated_delivery_days" int4,
  "ae_unsaleable" bool DEFAULT false,
  "is_seasonal" bool DEFAULT false,
  "is_fresh_daily" bool DEFAULT false,
  "hot_sell_ranking" int4,
  "last_sale_at" timestamp(6),
  "last_offline_at" timestamp(6),
  "hot_sell_config_id" int8,
  "expiration_reminder_before_n_days" int4,
  "ae_free_shipping_threshold_in_cent" int4 DEFAULT 0,
  "ae_shipping_info_last_updated_date" date,
  "ae_basic_info_last_updated_date" date
)
;
COMMENT ON COLUMN "items"."buy_quota" IS '每个买家帐号累计限购多少件, 0表示无限制';
COMMENT ON COLUMN "items"."no" IS '商品货号（为商品设置的外部编号）';
COMMENT ON COLUMN "items"."quantity" IS '总库存量';
COMMENT ON COLUMN "items"."fixed_freight" IS '统一运费';
COMMENT ON COLUMN "items"."fixed_freight_cost" IS '固定运费成本';
COMMENT ON COLUMN "items"."free_shipping" IS '是否参与包邮计划';
COMMENT ON COLUMN "items"."production_place" IS '产地';
COMMENT ON COLUMN "items"."allergen" IS '过敏原';
COMMENT ON COLUMN "items"."serving_per_package" IS '本包装包含份数';
COMMENT ON COLUMN "items"."serving_size" IS '每一份的份量';
COMMENT ON COLUMN "items"."expiration_date" IS '产品过期日期';
COMMENT ON COLUMN "items"."batch_reindex_date" IS '每晚批量同步ES日期';
COMMENT ON COLUMN "items"."not_eligible_for_free_gift" IS '商品是否不参与满赠';
COMMENT ON COLUMN "items"."first_sale_at" IS '首次上架开卖时间';
COMMENT ON COLUMN "items"."leader" IS '负责人';
COMMENT ON COLUMN "items"."gift_only" IS '只用作赠品，无法单独加购或直接购买';
COMMENT ON COLUMN "items"."deleted_at" IS '软删除时间';
COMMENT ON COLUMN "items"."ae_freight_info" IS 'AE物流信息';
COMMENT ON COLUMN "items"."is_ae_choice" IS '是否是AE官方产品';
COMMENT ON COLUMN "items"."ae_delivery_date_desc" IS 'AE发货时间描述, 例: Oct. 31 - Nov. 07';
COMMENT ON COLUMN "items"."ae_delivery_date" IS 'AE发货日期，AE产品的发货日期由AE计算';
COMMENT ON COLUMN "items"."ae_estimated_delivery_days" IS 'AE预估发货天数';
COMMENT ON COLUMN "items"."ae_unsaleable" IS 'AE端是否不可销售';
COMMENT ON COLUMN "items"."last_sale_at" IS '最近一次开卖时间';
COMMENT ON COLUMN "items"."last_offline_at" IS '最近一次下架时间';
COMMENT ON COLUMN "items"."expiration_reminder_before_n_days" IS '提前n天提示过期日期弹窗';
COMMENT ON COLUMN "items"."ae_free_shipping_threshold_in_cent" IS 'AE 免运费门槛';
COMMENT ON COLUMN "items"."ae_shipping_info_last_updated_date" IS 'AE商品物流信息最后更新日期';
COMMENT ON COLUMN "items"."ae_basic_info_last_updated_date" IS 'AE商品基础信息最后更新日期';

-- ----------------------------
-- Table structure for kuaidi_company_mappings
-- ----------------------------
CREATE TABLE "kuaidi_company_mappings" (
  "id" int8 NOT NULL DEFAULT nextval('kuaidi_company_mappings_id_seq'::regclass),
  "cn_name" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "code" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for live_comments
-- ----------------------------
CREATE TABLE "live_comments" (
  "id" int8 NOT NULL DEFAULT nextval('live_comments_id_seq'::regclass),
  "live_room_id" int8,
  "user_id" int8,
  "nickname" varchar COLLATE "pg_catalog"."default",
  "device_id" varchar COLLATE "pg_catalog"."default",
  "user_ip" varchar COLLATE "pg_catalog"."default",
  "content" text COLLATE "pg_catalog"."default",
  "commented_at" timestamp(6),
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for live_room_lotteries
-- ----------------------------
CREATE TABLE "live_room_lotteries" (
  "id" int8 NOT NULL DEFAULT nextval('live_room_lotteries_id_seq'::regclass),
  "name" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "luck_limit" int4 NOT NULL DEFAULT 0,
  "duration_in_minutes" int4 NOT NULL,
  "state" int4 NOT NULL DEFAULT 0,
  "started_at" timestamp(6),
  "participators_count" int4 NOT NULL DEFAULT 0,
  "award_cover" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "remark" varchar COLLATE "pg_catalog"."default",
  "live_room_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "draw_method" int4 NOT NULL DEFAULT 0
)
;

-- ----------------------------
-- Table structure for live_room_lottery_winning_users
-- ----------------------------
CREATE TABLE "live_room_lottery_winning_users" (
  "id" int8 NOT NULL DEFAULT nextval('live_room_lottery_winning_users_id_seq'::regclass),
  "live_room_lottery_id" int8,
  "user_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "address_id" int8,
  "receiver_properties" "public"."hstore",
  "live_room_id" int8
)
;

-- ----------------------------
-- Table structure for live_room_orders
-- ----------------------------
CREATE TABLE "live_room_orders" (
  "id" int8 NOT NULL DEFAULT nextval('live_room_orders_id_seq'::regclass),
  "live_room_id" int8,
  "order_id" int8,
  "user_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for live_room_skus
-- ----------------------------
CREATE TABLE "live_room_skus" (
  "id" int8 NOT NULL DEFAULT nextval('live_room_skus_id_seq'::regclass),
  "live_room_id" int8,
  "stock_keeping_unit_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for live_room_subscriptions
-- ----------------------------
CREATE TABLE "live_room_subscriptions" (
  "id" int8 NOT NULL DEFAULT nextval('live_room_subscriptions_id_seq'::regclass),
  "live_room_id" int8,
  "user_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for live_room_viewed_user_stats
-- ----------------------------
CREATE TABLE "live_room_viewed_user_stats" (
  "id" int8 NOT NULL DEFAULT nextval('live_room_viewed_user_stats_id_seq'::regclass),
  "count" int4 NOT NULL DEFAULT 0,
  "time_str" varchar COLLATE "pg_catalog"."default",
  "live_room_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;
COMMENT ON COLUMN "live_room_viewed_user_stats"."time_str" IS '精确到分钟的时间';

-- ----------------------------
-- Table structure for live_room_viewed_users
-- ----------------------------
CREATE TABLE "live_room_viewed_users" (
  "id" int8 NOT NULL DEFAULT nextval('live_room_viewed_users_id_seq'::regclass),
  "live_room_id" int8,
  "user_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for live_rooms
-- ----------------------------
CREATE TABLE "live_rooms" (
  "id" int8 NOT NULL DEFAULT nextval('live_rooms_id_seq'::regclass),
  "title" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "host_id" int8 NOT NULL,
  "host_nickname" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "start_at" timestamp(6) NOT NULL,
  "admin_user_id" int8 NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "app_push_protocol" int4 NOT NULL DEFAULT 1,
  "app_pull_protocol" int4 NOT NULL DEFAULT 0,
  "store_id" int8,
  "actual_viewed_count" int4 DEFAULT 0,
  "viewed_count_offset" int4 DEFAULT 0,
  "viewed_count_multiplier" int4 DEFAULT 1,
  "actual_liked_count" int4 DEFAULT 0,
  "liked_count_offset" int4 DEFAULT 0,
  "liked_count_multiplier" int4 DEFAULT 1,
  "actual_peak_concurrent_users_count" int4 DEFAULT 0,
  "actual_viewed_users_count" int4 DEFAULT 0,
  "actual_liked_users_count" int4 DEFAULT 0,
  "average_user_viewed_time_in_sec" int4 DEFAULT 0,
  "state" int4 DEFAULT 0,
  "finished_at" timestamp(6),
  "live_at" timestamp(6),
  "actual_comments_count" int4 DEFAULT 0,
  "actual_comment_users_count" int4 DEFAULT 0,
  "coupon_package_id" int8,
  "bg_img" varchar COLLATE "pg_catalog"."default",
  "bg_color" varchar COLLATE "pg_catalog"."default",
  "live_room_subscriptions_count" int4 DEFAULT 0,
  "announcement" varchar COLLATE "pg_catalog"."default",
  "highlighted_sku_id" int8,
  "subscription_noti_title" varchar COLLATE "pg_catalog"."default",
  "subscription_noti_body" varchar COLLATE "pg_catalog"."default",
  "custom_page_icon" varchar COLLATE "pg_catalog"."default",
  "custom_page_id" int8,
  "current_lottery_id" int8,
  "share_icon" varchar COLLATE "pg_catalog"."default",
  "subscription_count_offset" int4 DEFAULT 0,
  "subscription_count_multiplier" int4 DEFAULT 0,
  "lottery_win_limits" int4 DEFAULT 0,
  "orientation" int4 NOT NULL DEFAULT 0,
  "agora_vod_filename" varchar COLLATE "pg_catalog"."default",
  "agora_mp4_filenames" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[]
)
;
COMMENT ON COLUMN "live_rooms"."actual_viewed_count" IS '实际观看次数';
COMMENT ON COLUMN "live_rooms"."viewed_count_offset" IS '基础观看次数';
COMMENT ON COLUMN "live_rooms"."viewed_count_multiplier" IS '实际观看次数乘数';
COMMENT ON COLUMN "live_rooms"."actual_liked_count" IS '实际点赞次数';
COMMENT ON COLUMN "live_rooms"."liked_count_offset" IS '基础点赞次数';
COMMENT ON COLUMN "live_rooms"."liked_count_multiplier" IS '实际点赞次数乘数';
COMMENT ON COLUMN "live_rooms"."actual_peak_concurrent_users_count" IS '实际峰值在线人数';
COMMENT ON COLUMN "live_rooms"."actual_viewed_users_count" IS '实际观看人数';
COMMENT ON COLUMN "live_rooms"."actual_liked_users_count" IS '实际点赞人数';
COMMENT ON COLUMN "live_rooms"."average_user_viewed_time_in_sec" IS '平均观看时长';
COMMENT ON COLUMN "live_rooms"."actual_comments_count" IS '实际评论数';
COMMENT ON COLUMN "live_rooms"."actual_comment_users_count" IS '实际评论人数';
COMMENT ON COLUMN "live_rooms"."subscription_count_offset" IS '订阅基础数';
COMMENT ON COLUMN "live_rooms"."subscription_count_multiplier" IS '订阅数乘数';
COMMENT ON COLUMN "live_rooms"."lottery_win_limits" IS '中奖次数上限，0 表示不限制';

-- ----------------------------
-- Table structure for logistics
-- ----------------------------
CREATE TABLE "logistics" (
  "id" int8 NOT NULL DEFAULT nextval('logistics_id_seq'::regclass),
  "no" varchar COLLATE "pg_catalog"."default",
  "company" varchar COLLATE "pg_catalog"."default",
  "traces" jsonb,
  "remark" varchar COLLATE "pg_catalog"."default",
  "order_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "shipment_no" varchar COLLATE "pg_catalog"."default",
  "sku_ids" int4[] DEFAULT '{}'::integer[],
  "is_delivered" bool DEFAULT false,
  "ae_order_no" varchar COLLATE "pg_catalog"."default"
)
;
COMMENT ON COLUMN "logistics"."remark" IS '备注(用于多个物流单时备注该物流单包含的商品)';
COMMENT ON COLUMN "logistics"."shipment_no" IS 'erp发货单号';
COMMENT ON COLUMN "logistics"."ae_order_no" IS 'AE 订单号';

-- ----------------------------
-- Table structure for marketing_messages
-- ----------------------------
CREATE TABLE "marketing_messages" (
  "id" int8 NOT NULL DEFAULT nextval('marketing_messages_id_seq'::regclass),
  "content" varchar COLLATE "pg_catalog"."default",
  "store_id" int8,
  "admin_user_id" int8,
  "state" int4 DEFAULT 1,
  "user_ids" int4[] DEFAULT '{}'::integer[],
  "push_at" timestamp(6),
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "sms_platform" varchar COLLATE "pg_catalog"."default" DEFAULT 'aws'::character varying,
  "manual_user_ids" int4[] DEFAULT '{}'::integer[]
)
;
COMMENT ON COLUMN "marketing_messages"."state" IS 'draft: 0, pending: 1, pushed: 2';
COMMENT ON COLUMN "marketing_messages"."user_ids" IS '指定用户';
COMMENT ON COLUMN "marketing_messages"."sms_platform" IS '短信发送平台';
COMMENT ON COLUMN "marketing_messages"."manual_user_ids" IS '手动添加用户';

-- ----------------------------
-- Table structure for members
-- ----------------------------
CREATE TABLE "members" (
  "id" int8 NOT NULL DEFAULT nextval('members_id_seq'::regclass),
  "mobile" varchar COLLATE "pg_catalog"."default",
  "birthday" date,
  "available_integral" int4 DEFAULT 0,
  "blocked_integral" int4 DEFAULT 0,
  "cumulative_integral" int4 DEFAULT 0,
  "user_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "inviter_id" int8,
  "invite_code" varchar COLLATE "pg_catalog"."default",
  "assigned_app_newbie_coupon" bool DEFAULT false,
  "app_available_integral" int4 DEFAULT 0,
  "app_blocked_integral" int4 DEFAULT 0,
  "app_cumulative_integral" int4 DEFAULT 0,
  "channel" int4 DEFAULT 0,
  "email" varchar COLLATE "pg_catalog"."default",
  "receive_activity_email" bool DEFAULT false,
  "can_edit_birthday" bool DEFAULT true,
  "email_verified_at" timestamp(6),
  "first_name" varchar COLLATE "pg_catalog"."default",
  "last_name" varchar COLLATE "pg_catalog"."default",
  "email_confirmation_token" varchar COLLATE "pg_catalog"."default"
)
;
COMMENT ON COLUMN "members"."available_integral" IS '可用积分';
COMMENT ON COLUMN "members"."blocked_integral" IS '冻结积分';
COMMENT ON COLUMN "members"."cumulative_integral" IS '累积获取积分';
COMMENT ON COLUMN "members"."app_available_integral" IS 'APP 可用积分';
COMMENT ON COLUMN "members"."app_blocked_integral" IS 'APP 冻结积分';
COMMENT ON COLUMN "members"."app_cumulative_integral" IS 'APP 累积获取积分';

-- ----------------------------
-- Table structure for message_unread_counters
-- ----------------------------
CREATE TABLE "message_unread_counters" (
  "id" int8 NOT NULL DEFAULT nextval('message_unread_counters_id_seq'::regclass),
  "user_id" int8,
  "order_tracking_count" int4 NOT NULL DEFAULT 0,
  "customer_service_count" int4 NOT NULL DEFAULT 0,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "sku_in_stock_count" int4 DEFAULT 0
)
;
COMMENT ON COLUMN "message_unread_counters"."order_tracking_count" IS '订单追踪未读消息数';
COMMENT ON COLUMN "message_unread_counters"."customer_service_count" IS '客服通知未读消息数';

-- ----------------------------
-- Table structure for mine_page_activity_setting_translations
-- ----------------------------
CREATE TABLE "mine_page_activity_setting_translations" (
  "id" int8 NOT NULL DEFAULT nextval('mine_page_activity_setting_translations_id_seq'::regclass),
  "mine_page_activity_setting_id" int8 NOT NULL,
  "locale" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "name" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for mine_page_activity_settings
-- ----------------------------
CREATE TABLE "mine_page_activity_settings" (
  "id" int8 NOT NULL DEFAULT nextval('mine_page_activity_settings_id_seq'::regclass),
  "icon" varchar COLLATE "pg_catalog"."default",
  "custom_page_id" int8,
  "store_id" int8,
  "position" int4 DEFAULT 999,
  "enabled" bool DEFAULT true,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "path" varchar COLLATE "pg_catalog"."default"
)
;
COMMENT ON COLUMN "mine_page_activity_settings"."icon" IS '活动图标';
COMMENT ON COLUMN "mine_page_activity_settings"."position" IS '排序';
COMMENT ON COLUMN "mine_page_activity_settings"."enabled" IS '是否启用';
COMMENT ON COLUMN "mine_page_activity_settings"."path" IS '跳转页面路径';

-- ----------------------------
-- Table structure for mobile_blacklists
-- ----------------------------
CREATE TABLE "mobile_blacklists" (
  "id" int8 NOT NULL DEFAULT nextval('mobile_blacklists_id_seq'::regclass),
  "user_id" int8,
  "mobile" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "enabled" bool NOT NULL DEFAULT true,
  "live_comment_disabled" bool NOT NULL DEFAULT true,
  "live_lottery_disabled" bool NOT NULL DEFAULT true,
  "started_at" timestamp(6),
  "ended_at" timestamp(6),
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "order_disabled" bool DEFAULT true,
  "push_notification_disabled" bool DEFAULT false,
  "marketing_sms_disabled" bool DEFAULT false
)
;
COMMENT ON COLUMN "mobile_blacklists"."push_notification_disabled" IS '不可接收推送通知';
COMMENT ON COLUMN "mobile_blacklists"."marketing_sms_disabled" IS '不可接收营销短信';

-- ----------------------------
-- Table structure for multi_lang_config_translations
-- ----------------------------
CREATE TABLE "multi_lang_config_translations" (
  "id" int8 NOT NULL DEFAULT nextval('multi_lang_config_translations_id_seq'::regclass),
  "multi_lang_config_id" int8 NOT NULL,
  "locale" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "value" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for multi_lang_configs
-- ----------------------------
CREATE TABLE "multi_lang_configs" (
  "id" int8 NOT NULL DEFAULT nextval('multi_lang_configs_id_seq'::regclass),
  "key" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "name" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "kind" int4 DEFAULT 0,
  "store_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "hint" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for nutrition_translations
-- ----------------------------
CREATE TABLE "nutrition_translations" (
  "id" int8 NOT NULL DEFAULT nextval('nutrition_translations_id_seq'::regclass),
  "nutrition_id" int8 NOT NULL,
  "locale" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "name" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for nutritions
-- ----------------------------
CREATE TABLE "nutritions" (
  "id" int8 NOT NULL DEFAULT nextval('nutritions_id_seq'::regclass),
  "slug" varchar COLLATE "pg_catalog"."default",
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for operation_records
-- ----------------------------
CREATE TABLE "operation_records" (
  "id" int8 NOT NULL DEFAULT nextval('operation_records_id_seq'::regclass),
  "admin_user_id" int8,
  "operatable_type" varchar COLLATE "pg_catalog"."default",
  "operatable_id" int8,
  "content" text COLLATE "pg_catalog"."default",
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "deleted_at" timestamp(6),
  "store_id" int8,
  "channel" int4 DEFAULT 1
)
;

-- ----------------------------
-- Table structure for order_date_analyses
-- ----------------------------
CREATE TABLE "order_date_analyses" (
  "id" int8 NOT NULL DEFAULT nextval('order_date_analyses_id_seq'::regclass),
  "delivery_date" date,
  "store_id" int4,
  "distinct_address_count" int4 DEFAULT 0,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for order_invoices
-- ----------------------------
CREATE TABLE "order_invoices" (
  "id" int8 NOT NULL DEFAULT nextval('order_invoices_id_seq'::regclass),
  "no" varchar COLLATE "pg_catalog"."default",
  "order_id" int8,
  "state" int4 DEFAULT 0,
  "invoice_properties" "public"."hstore",
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for order_items
-- ----------------------------
CREATE TABLE "order_items" (
  "id" int8 NOT NULL DEFAULT nextval('order_items_id_seq'::regclass),
  "quantity" int4 DEFAULT 0,
  "amount_in_cent" int4 DEFAULT 0,
  "price_in_cent" int4 DEFAULT 0,
  "stock_keeping_unit_id" int8,
  "order_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "properties_text" varchar COLLATE "pg_catalog"."default",
  "title" varchar COLLATE "pg_catalog"."default",
  "image" varchar COLLATE "pg_catalog"."default",
  "item_id" int4,
  "weight_in_gram" int4 NOT NULL DEFAULT 0,
  "groups" json DEFAULT '[]'::json,
  "sku_type" int4 DEFAULT 1,
  "real_price_in_cent" int4,
  "store_id" int8,
  "display_price_in_cent" int4 DEFAULT 0,
  "promo_code_id" int8,
  "gst_percent" int4 DEFAULT 0,
  "gst_amount_in_cent" numeric(12,2) DEFAULT 0.0,
  "marketing_mode" int4 DEFAULT 1,
  "short_title" varchar COLLATE "pg_catalog"."default",
  "source_page_name" int4,
  "source_channel" int4,
  "source_custom_list_id" int4,
  "source_extra_hash" json,
  "pool_price_in_cent" int4,
  "strikethrough_price_in_cent" int4,
  "strikethrough_amount_in_cent" int4,
  "is_new_user_price" bool DEFAULT false,
  "live_top" bool DEFAULT false,
  "not_eligible_for_free_gift" bool DEFAULT false,
  "service_amount_in_cent" int4 DEFAULT 0,
  "cost_integral" int4 DEFAULT 0,
  "gift_card_amount_in_cent" int4 DEFAULT 0,
  "real_amount_in_cent" int4 DEFAULT 0,
  "ae_gst_amount_in_cent" int4 DEFAULT 0,
  "is_box_regulation" bool DEFAULT false
)
;
COMMENT ON COLUMN "order_items"."amount_in_cent" IS '订单项总价';
COMMENT ON COLUMN "order_items"."price_in_cent" IS '订单项单价';
COMMENT ON COLUMN "order_items"."live_top" IS '直播间置顶并免邮';
COMMENT ON COLUMN "order_items"."not_eligible_for_free_gift" IS '商品是否不参与满赠';
COMMENT ON COLUMN "order_items"."service_amount_in_cent" IS '均摊手续费($)';
COMMENT ON COLUMN "order_items"."cost_integral" IS '均摊金币数量';
COMMENT ON COLUMN "order_items"."gift_card_amount_in_cent" IS '均摊礼品卡($)';
COMMENT ON COLUMN "order_items"."real_amount_in_cent" IS '最终的优惠金额';

-- ----------------------------
-- Table structure for orders
-- ----------------------------
CREATE TABLE "orders" (
  "id" int8 NOT NULL DEFAULT nextval('orders_id_seq'::regclass),
  "no" varchar COLLATE "pg_catalog"."default",
  "payment_in_cent" int4 DEFAULT 0,
  "status" int4 DEFAULT 1,
  "amount_in_cent" int4 DEFAULT 0,
  "paid_at" timestamp(6),
  "receiver_properties" "public"."hstore",
  "transaction_id" varchar COLLATE "pg_catalog"."default",
  "finished_at" timestamp(6),
  "buyer_message" varchar COLLATE "pg_catalog"."default",
  "refund_no" varchar COLLATE "pg_catalog"."default",
  "prepay_id" varchar COLLATE "pg_catalog"."default",
  "cancel_reason" varchar COLLATE "pg_catalog"."default",
  "actually_amount_in_cent" int4 DEFAULT 0,
  "user_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "quantity" int4 DEFAULT 0,
  "delivered_at" timestamp(6),
  "confirmed_at" timestamp(6),
  "remark" text COLLATE "pg_catalog"."default",
  "province_id" int8,
  "freight_in_cent" int4 NOT NULL DEFAULT 0,
  "after_sales_count" int4 DEFAULT 0,
  "total_payment_in_cent" int4 NOT NULL DEFAULT 0,
  "coupon_id" int8,
  "original_payment_in_cent" int4,
  "groupon_activity_id" int8,
  "sku_groupon_id" int8,
  "type" varchar COLLATE "pg_catalog"."default",
  "groupon_id" int8,
  "is_sent_but_status_not_show" bool DEFAULT false,
  "apply_reason" varchar COLLATE "pg_catalog"."default",
  "scene_code" varchar COLLATE "pg_catalog"."default",
  "gift_activity_id" int8,
  "gifts_properties" json,
  "cost_integral" int4 DEFAULT 0,
  "self_pick_up_id" int8,
  "delivery_type" int4 DEFAULT 1,
  "sync_status" int4 DEFAULT 1,
  "synced_at" timestamp(6),
  "wechat_service_percentage" float8 DEFAULT 0.0,
  "credit_card_service_percentage" float8 DEFAULT 0.0,
  "wechat_payment_in_cent" int4 DEFAULT 0,
  "credit_card_payment_in_cent" int4 DEFAULT 0,
  "aud_to_cny_exchange_rate" numeric(12,4) DEFAULT 0.0,
  "delivery_date" varchar COLLATE "pg_catalog"."default",
  "prefer_time" varchar COLLATE "pg_catalog"."default",
  "authority_to_leave" bool DEFAULT false,
  "channel" int4 DEFAULT 1,
  "omipay_payment_dollar_in_cent" int4 DEFAULT 0,
  "omipay_service_amount_dollar_in_cent" int4 DEFAULT 0,
  "omipay_payment_in_cent" int4 DEFAULT 0,
  "original_freight_in_cent" int4,
  "final_amount_in_cent" int4,
  "freight_cost_in_cent" int4 DEFAULT 0,
  "freight_remark" varchar COLLATE "pg_catalog"."default",
  "payment_type" varchar COLLATE "pg_catalog"."default",
  "store_id" int8,
  "integral_received_from_one_yuan" int4 DEFAULT 0,
  "integral_deducted_from_one_yuan" int4 DEFAULT 0,
  "omipay_transaction_id" varchar COLLATE "pg_catalog"."default",
  "gift_card_coupon_id" int8,
  "gift_card_amount_in_cent" int4 DEFAULT 0,
  "omipay_platform" varchar COLLATE "pg_catalog"."default",
  "delivery_track" varchar COLLATE "pg_catalog"."default",
  "gift_coupon_template_id" int4,
  "mark_for_orders_limit" bool DEFAULT true,
  "promo_code_id" int8,
  "delivery_time_id" int4,
  "next_day_delivery" bool DEFAULT false,
  "deleted_by_user_at" timestamp(6),
  "try_payment_times" int4,
  "pool_coupon_template_ids" int4[],
  "pool_gifts_properties" json,
  "active_pools" json DEFAULT '{}'::json,
  "payment_in_progress" bool DEFAULT false,
  "strikethrough_amount_in_cent" int4,
  "order_finished_reward_integral" bool DEFAULT true,
  "live_top" bool DEFAULT false,
  "same_day_delivery_time_id" int8,
  "same_day_delivery_time_period_id" int8,
  "deliver_to_door" bool DEFAULT false,
  "supay_payment_dollar_in_cent" int4 DEFAULT 0,
  "supay_payment_in_cent" int4 DEFAULT 0,
  "supay_service_amount_dollar_in_cent" int4 DEFAULT 0,
  "supay_platform" varchar COLLATE "pg_catalog"."default",
  "actual_credit_card_service_amount_in_cent" int4 DEFAULT 0,
  "actual_credit_card_service_percentage" numeric(5,2) DEFAULT 0.0,
  "warehouse_order_id" int8,
  "express_carrier" varchar COLLATE "pg_catalog"."default",
  "deliver_to_door_service_fee_in_cent" int4 DEFAULT 0,
  "is_child" bool DEFAULT false,
  "stripe_transaction_id" varchar COLLATE "pg_catalog"."default",
  "eta" timestamp(6),
  "ata" timestamp(6),
  "delivery_path" varchar COLLATE "pg_catalog"."default",
  "ae_drop_shipper" bool DEFAULT false,
  "ae_error_response" jsonb,
  "ae_order_list" varchar[] COLLATE "pg_catalog"."default",
  "ae_gst_amount_in_cent" int4 DEFAULT 0,
  "delivery_time_period_setting_id" int8,
  "long_distance_fee_in_cent" int4 DEFAULT 0,
  "time_period_fee_in_cent" int4 DEFAULT 0,
  "box_regulation_fee_in_cent" int4 DEFAULT 0,
  "box_regulation_quantity" int4 DEFAULT 0,
  "free_box_regulation_quantity" int4 DEFAULT 0,
  "per_box_charge_in_cent" int4 DEFAULT 0,
  "package_service_fee_in_cent" int4 DEFAULT 0,
  "package_service_discount_in_cent" int4 DEFAULT 0,
  "original_package_service_fee_in_cent" int4 DEFAULT 0,
  "address_housing_type" int4 DEFAULT 1
)
;
COMMENT ON COLUMN "orders"."status" IS '1: 待付款, 2: 待發貨, 3: 待收貨, 4: 退款中, 5: 交易成功, 6: 交易關閉, 7: 已收貨, 8: 申請退款, 9: 3DS風險支付, 10: 直播待審核';
COMMENT ON COLUMN "orders"."receiver_properties" IS '收件人信息';
COMMENT ON COLUMN "orders"."transaction_id" IS '外部支付单号';
COMMENT ON COLUMN "orders"."finished_at" IS '订单完成时间，通过计算判断是否可售后';
COMMENT ON COLUMN "orders"."actually_amount_in_cent" IS '订单实际金额，去除部分退款之后实际金额';
COMMENT ON COLUMN "orders"."remark" IS '卖家备注';
COMMENT ON COLUMN "orders"."delivery_type" IS '1 自派 2 郵寄 3 自提 4 虛擬';
COMMENT ON COLUMN "orders"."sync_status" IS '同步到 wms 状态';
COMMENT ON COLUMN "orders"."delivery_date" IS '配送日期';
COMMENT ON COLUMN "orders"."prefer_time" IS '配送时间段';
COMMENT ON COLUMN "orders"."freight_cost_in_cent" IS '订单运费成本';
COMMENT ON COLUMN "orders"."freight_remark" IS '订单运费备注';
COMMENT ON COLUMN "orders"."mark_for_orders_limit" IS '是否计算入每日上限订单数';
COMMENT ON COLUMN "orders"."try_payment_times" IS '用户尝试支付次数（只记信用卡支付）';
COMMENT ON COLUMN "orders"."live_top" IS '直播间置顶并免邮';
COMMENT ON COLUMN "orders"."supay_payment_dollar_in_cent" IS 'Supay支付金额，单位：AUD';
COMMENT ON COLUMN "orders"."supay_payment_in_cent" IS 'Supay支付金额，单位：CNY';
COMMENT ON COLUMN "orders"."actual_credit_card_service_percentage" IS '实际信用卡服务费百分比';
COMMENT ON COLUMN "orders"."express_carrier" IS '第三方邮寄派送，例如：KUAIMA';
COMMENT ON COLUMN "orders"."deliver_to_door_service_fee_in_cent" IS '送货上门服务费';
COMMENT ON COLUMN "orders"."is_child" IS '是否加单的子单';
COMMENT ON COLUMN "orders"."eta" IS 'WMS预计配送时间';
COMMENT ON COLUMN "orders"."ata" IS 'WMS实际配送时间';
COMMENT ON COLUMN "orders"."delivery_path" IS '配送路线';
COMMENT ON COLUMN "orders"."long_distance_fee_in_cent" IS '远程运费';
COMMENT ON COLUMN "orders"."time_period_fee_in_cent" IS '指定时间段运费';
COMMENT ON COLUMN "orders"."box_regulation_fee_in_cent" IS '超出箱规费用';
COMMENT ON COLUMN "orders"."box_regulation_quantity" IS '箱规数量';
COMMENT ON COLUMN "orders"."free_box_regulation_quantity" IS '免费箱规数量';
COMMENT ON COLUMN "orders"."per_box_charge_in_cent" IS '每个箱规费用';
COMMENT ON COLUMN "orders"."package_service_fee_in_cent" IS '包装服务费';
COMMENT ON COLUMN "orders"."package_service_discount_in_cent" IS '包装服务费';
COMMENT ON COLUMN "orders"."original_package_service_fee_in_cent" IS '原始包装服务费';
COMMENT ON COLUMN "orders"."address_housing_type" IS '地址房屋类型: 1-住宅, 2-公寓, 3-公司';

-- ----------------------------
-- Table structure for overseas_student_applications
-- ----------------------------
CREATE TABLE "overseas_student_applications" (
  "id" int8 NOT NULL DEFAULT nextval('overseas_student_applications_id_seq'::regclass),
  "nickname" varchar COLLATE "pg_catalog"."default",
  "gender" int4,
  "birthday" date,
  "school" varchar COLLATE "pg_catalog"."default",
  "email" varchar COLLATE "pg_catalog"."default",
  "student_number" varchar COLLATE "pg_catalog"."default",
  "student_image_obverse_side" varchar COLLATE "pg_catalog"."default",
  "student_image_reverse_side" varchar COLLATE "pg_catalog"."default",
  "status" int4 DEFAULT 1,
  "user_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for page_popups
-- ----------------------------
CREATE TABLE "page_popups" (
  "id" int8 NOT NULL DEFAULT nextval('page_popups_id_seq'::regclass),
  "title" varchar COLLATE "pg_catalog"."default",
  "image" varchar COLLATE "pg_catalog"."default",
  "path" varchar COLLATE "pg_catalog"."default",
  "for_new_user" bool DEFAULT false,
  "start_at" timestamp(6),
  "end_at" timestamp(6),
  "position" int4 DEFAULT 0,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "store_id" int8,
  "is_always" bool DEFAULT false,
  "is_fullscreen" bool DEFAULT false,
  "page_type" int4 DEFAULT 1,
  "au_suburb_ids" int4[] DEFAULT '{}'::integer[],
  "locales" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{zh-CN,zh-TW}'::character varying[]
)
;

-- ----------------------------
-- Table structure for pages
-- ----------------------------
CREATE TABLE "pages" (
  "id" int8 NOT NULL DEFAULT nextval('pages_id_seq'::regclass),
  "name" varchar COLLATE "pg_catalog"."default",
  "kind" int4,
  "content" text COLLATE "pg_catalog"."default",
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "cover" varchar COLLATE "pg_catalog"."default",
  "desc" varchar COLLATE "pg_catalog"."default",
  "position" int4 DEFAULT 0
)
;

-- ----------------------------
-- Table structure for payment_settings
-- ----------------------------
CREATE TABLE "payment_settings" (
  "id" int8 NOT NULL DEFAULT nextval('payment_settings_id_seq'::regclass),
  "store_id" int8,
  "wechat_service_percentage" float8,
  "vm_credit_card_service_percentage" float8,
  "unionpay_credit_card_service_percentage" float8,
  "exchange_rate_rise_percentage" float8,
  "omipay_wechat_service_percentage" float8,
  "omipay_alipay_service_percentage" float8,
  "supay_wechat_service_percentage" float8,
  "supay_alipay_service_percentage" float8,
  "enable_commweb_3ds_auth" bool DEFAULT true,
  "apple_pay_service_percentage" float8,
  "cba_apple_pay_service_percentage" float8,
  "cba_google_pay_service_percentage" float8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "amex_credit_card_service_percentage" float8,
  "no_transaction_fee_over_amount_in_cent" int4,
  "display_cba_credit_card_service" bool DEFAULT true,
  "display_unionpay_credit_card_service" bool DEFAULT true,
  "display_omipay_wechat_service" bool DEFAULT false,
  "display_omipay_alipay_service" bool DEFAULT false,
  "display_supay_wechat_service" bool DEFAULT false,
  "display_supay_alipay_service" bool DEFAULT false,
  "display_apple_pay_service" bool DEFAULT true,
  "display_cba_apple_pay_service" bool DEFAULT true,
  "display_cba_google_pay_service" bool DEFAULT true,
  "stripe_credit_card_service_percentage" float8,
  "stripe_apple_pay_service_percentage" float8,
  "stripe_google_pay_service_percentage" float8,
  "display_stripe_credit_card_service" bool DEFAULT false,
  "display_stripe_apple_pay_service" bool DEFAULT false,
  "display_stripe_google_pay_service" bool DEFAULT false
)
;
COMMENT ON COLUMN "payment_settings"."no_transaction_fee_over_amount_in_cent" IS '实付满金额免手续费，为空时必收手续费';

-- ----------------------------
-- Table structure for payments
-- ----------------------------
CREATE TABLE "payments" (
  "id" int8 NOT NULL DEFAULT nextval('payments_id_seq'::regclass),
  "transaction_id" varchar COLLATE "pg_catalog"."default",
  "amount_in_cent" numeric(12,2),
  "type" varchar COLLATE "pg_catalog"."default",
  "paymentable_type" varchar COLLATE "pg_catalog"."default",
  "paymentable_id" int8,
  "status" int4 DEFAULT 1,
  "payment_type" int4 DEFAULT 1,
  "response" json DEFAULT '{}'::json,
  "parent_id" int8,
  "refund_amount_in_cent" numeric(12,2) DEFAULT 0.0,
  "refunding_amount_in_cent" numeric(12,2) DEFAULT 0.0,
  "service_amount_in_cent" numeric(12,2) DEFAULT 0.0,
  "completed_at" timestamp(6),
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "no" varchar COLLATE "pg_catalog"."default",
  "channel" int4 DEFAULT 1,
  "platform" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for preferential_pool_translations
-- ----------------------------
CREATE TABLE "preferential_pool_translations" (
  "id" int8 NOT NULL DEFAULT nextval('preferential_pool_translations_id_seq'::regclass),
  "preferential_pool_id" int8 NOT NULL,
  "locale" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "title" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for preferential_pools
-- ----------------------------
CREATE TABLE "preferential_pools" (
  "id" int8 NOT NULL DEFAULT nextval('preferential_pools_id_seq'::regclass),
  "kind" int4 DEFAULT 1,
  "sku_ids" int4[] DEFAULT '{}'::integer[],
  "threshold_kind" int4 DEFAULT 1,
  "at_least_amount_in_cent" int4,
  "at_least_quantity" int4,
  "start_at" timestamp(6),
  "end_at" timestamp(6),
  "preferences" json DEFAULT '{}'::json,
  "enabled" bool DEFAULT true,
  "store_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;
COMMENT ON COLUMN "preferential_pools"."kind" IS '优惠类型';
COMMENT ON COLUMN "preferential_pools"."threshold_kind" IS '门槛类型';
COMMENT ON COLUMN "preferential_pools"."at_least_amount_in_cent" IS '门槛金额';
COMMENT ON COLUMN "preferential_pools"."at_least_quantity" IS '门槛数量';
COMMENT ON COLUMN "preferential_pools"."start_at" IS '活动开始时间';
COMMENT ON COLUMN "preferential_pools"."end_at" IS '活动结束时间';
COMMENT ON COLUMN "preferential_pools"."preferences" IS '优惠内容';
COMMENT ON COLUMN "preferential_pools"."enabled" IS '是否启用';

-- ----------------------------
-- Table structure for products
-- ----------------------------
CREATE TABLE "products" (
  "id" int8 NOT NULL DEFAULT nextval('products_id_seq'::regclass),
  "title" varchar COLLATE "pg_catalog"."default",
  "sub_title" varchar COLLATE "pg_catalog"."default",
  "description" text COLLATE "pg_catalog"."default",
  "shared_description" varchar COLLATE "pg_catalog"."default",
  "cover" varchar COLLATE "pg_catalog"."default",
  "share_cover" varchar COLLATE "pg_catalog"."default",
  "main_images" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "detail_video" varchar COLLATE "pg_catalog"."default",
  "detail_images" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "actual_monthly_sales_count" int4 NOT NULL DEFAULT 0,
  "category_id" int8,
  "brand_id" int8,
  "store_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "qa_and_guarantee_id" int8,
  "monthly_sales_count_offset" int4 DEFAULT 0,
  "sales_count_offset" int4 DEFAULT 0,
  "items_count" int4 DEFAULT 0,
  "minor_category_id" int4,
  "short_title" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for promo_code_templates
-- ----------------------------
CREATE TABLE "promo_code_templates" (
  "id" int8 NOT NULL DEFAULT nextval('promo_code_templates_id_seq'::regclass),
  "store_id" int8,
  "title" varchar COLLATE "pg_catalog"."default",
  "enabled" bool DEFAULT false,
  "start_on" date,
  "end_on" date,
  "remark" varchar COLLATE "pg_catalog"."default",
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "display_in_item_detail" bool DEFAULT false,
  "user_kind" int4 DEFAULT 1,
  "use_times_kind" int4 DEFAULT 1,
  "purpose" int4 DEFAULT 1
)
;
COMMENT ON COLUMN "promo_code_templates"."user_kind" IS '用户类型，1为全部用户，2为新用户';
COMMENT ON COLUMN "promo_code_templates"."use_times_kind" IS '使用次数类型，1为不限，2为每人限用1次';
COMMENT ON COLUMN "promo_code_templates"."purpose" IS '用途';

-- ----------------------------
-- Table structure for promo_codes
-- ----------------------------
CREATE TABLE "promo_codes" (
  "id" int8 NOT NULL DEFAULT nextval('promo_codes_id_seq'::regclass),
  "code" varchar COLLATE "pg_catalog"."default",
  "order_id" int8,
  "promo_code_template_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "store_id" int4,
  "total_avaliable_count" int4 NOT NULL DEFAULT 1,
  "used_count" int4 NOT NULL DEFAULT 0
)
;

-- ----------------------------
-- Table structure for promo_stock_keeping_units
-- ----------------------------
CREATE TABLE "promo_stock_keeping_units" (
  "id" int8 NOT NULL DEFAULT nextval('promo_stock_keeping_units_id_seq'::regclass),
  "promo_code_template_id" int8,
  "stock_keeping_unit_id" int8,
  "price_in_cent" int4,
  "quantity" int4,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;
COMMENT ON COLUMN "promo_stock_keeping_units"."price_in_cent" IS 'SKU 单价';
COMMENT ON COLUMN "promo_stock_keeping_units"."quantity" IS 'SKU 数量';

-- ----------------------------
-- Table structure for provinces
-- ----------------------------
CREATE TABLE "provinces" (
  "id" int8 NOT NULL DEFAULT nextval('provinces_id_seq'::regclass),
  "name" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "kind" int4 DEFAULT 1,
  "code" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for push_message_read_logs
-- ----------------------------
CREATE TABLE "push_message_read_logs" (
  "id" int8 NOT NULL DEFAULT nextval('push_message_read_logs_id_seq'::regclass),
  "user_id" int8,
  "push_message_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "details_viewed" bool DEFAULT false
)
;

-- ----------------------------
-- Table structure for push_messages
-- ----------------------------
CREATE TABLE "push_messages" (
  "id" int8 NOT NULL DEFAULT nextval('push_messages_id_seq'::regclass),
  "admin_user_id" int8,
  "title" varchar COLLATE "pg_catalog"."default",
  "content" text COLLATE "pg_catalog"."default",
  "state" int4 DEFAULT 0,
  "push_at" timestamp(6),
  "uv" int4 DEFAULT 0,
  "pv" int4 DEFAULT 0,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "image" varchar COLLATE "pg_catalog"."default",
  "store_id" int8,
  "kind" int4 DEFAULT 0,
  "path_customized" bool DEFAULT false,
  "path_customized_type" varchar COLLATE "pg_catalog"."default",
  "path_customized_id" int8,
  "user_ids" int4[] DEFAULT '{}'::integer[],
  "user_locales" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{zh-CN,zh-TW}'::character varying[]
)
;

-- ----------------------------
-- Table structure for qa_and_guarantee_translations
-- ----------------------------
CREATE TABLE "qa_and_guarantee_translations" (
  "id" int8 NOT NULL DEFAULT nextval('qa_and_guarantee_translations_id_seq'::regclass),
  "qa_and_guarantee_id" int8 NOT NULL,
  "locale" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "image" varchar COLLATE "pg_catalog"."default",
  "title" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for qa_and_guarantees
-- ----------------------------
CREATE TABLE "qa_and_guarantees" (
  "id" int8 NOT NULL DEFAULT nextval('qa_and_guarantees_id_seq'::regclass),
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "web_image" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for random_reduction_coupon_template_rules
-- ----------------------------
CREATE TABLE "random_reduction_coupon_template_rules" (
  "id" int8 NOT NULL DEFAULT nextval('random_reduction_coupon_template_rules_id_seq'::regclass),
  "min_amount_in_cent" int4 NOT NULL DEFAULT 0,
  "max_amount_in_cent" int4 NOT NULL DEFAULT 0,
  "max_quantity" int4 NOT NULL DEFAULT 0,
  "used_quantity" int4 NOT NULL DEFAULT 0,
  "coupon_template_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for report_pages
-- ----------------------------
CREATE TABLE "report_pages" (
  "id" int8 NOT NULL DEFAULT nextval('report_pages_id_seq'::regclass),
  "name" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "content" text COLLATE "pg_catalog"."default" NOT NULL,
  "creator_id" int4 NOT NULL,
  "admin_user_ids" int4[] DEFAULT '{}'::integer[],
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;
COMMENT ON COLUMN "report_pages"."admin_user_ids" IS '可查看的管理员用户';

-- ----------------------------
-- Table structure for role_templates
-- ----------------------------
CREATE TABLE "role_templates" (
  "id" int8 NOT NULL DEFAULT nextval('role_templates_id_seq'::regclass),
  "name" varchar COLLATE "pg_catalog"."default",
  "permissions" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for same_day_delivery_cart_items
-- ----------------------------
CREATE TABLE "same_day_delivery_cart_items" (
  "id" int8 NOT NULL DEFAULT nextval('same_day_delivery_cart_items_id_seq'::regclass),
  "quantity" int4 DEFAULT 1,
  "same_day_delivery_cart_id" int8,
  "stock_keeping_unit_id" int8,
  "deleted_at" timestamp(6),
  "store_id" int8,
  "source_page_name" int4,
  "source_channel" int4,
  "source_custom_list_id" int4,
  "source_extra_hash" json,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for same_day_delivery_carts
-- ----------------------------
CREATE TABLE "same_day_delivery_carts" (
  "id" int8 NOT NULL DEFAULT nextval('same_day_delivery_carts_id_seq'::regclass),
  "user_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for same_day_delivery_time_periods
-- ----------------------------
CREATE TABLE "same_day_delivery_time_periods" (
  "id" int8 NOT NULL DEFAULT nextval('same_day_delivery_time_periods_id_seq'::regclass),
  "time_period" varchar COLLATE "pg_catalog"."default",
  "kind" int4,
  "time_window" int4,
  "address_count_limit" int4,
  "enabled" bool DEFAULT true,
  "same_day_delivery_time_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "free_shipping_amount_in_cent" int4,
  "extra_shipping_amount_in_cent" int4
)
;
COMMENT ON COLUMN "same_day_delivery_time_periods"."free_shipping_amount_in_cent" IS '免额外运费门槛';
COMMENT ON COLUMN "same_day_delivery_time_periods"."extra_shipping_amount_in_cent" IS '额外运费';

-- ----------------------------
-- Table structure for same_day_delivery_times
-- ----------------------------
CREATE TABLE "same_day_delivery_times" (
  "id" int8 NOT NULL DEFAULT nextval('same_day_delivery_times_id_seq'::regclass),
  "name" varchar COLLATE "pg_catalog"."default",
  "weekdays" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "limited_by_orders_limit_every_day" bool DEFAULT true,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for schema_migrations
-- ----------------------------
CREATE TABLE "schema_migrations" (
  "version" varchar COLLATE "pg_catalog"."default" NOT NULL
)
;

-- ----------------------------
-- Table structure for self_pick_order_date_analyses
-- ----------------------------
CREATE TABLE "self_pick_order_date_analyses" (
  "id" int8 NOT NULL DEFAULT nextval('self_pick_order_date_analyses_id_seq'::regclass),
  "self_pick_up_id" int4,
  "delivery_date" date,
  "orders_count" int4 DEFAULT 0,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for self_pick_ups
-- ----------------------------
CREATE TABLE "self_pick_ups" (
  "id" int8 NOT NULL DEFAULT nextval('self_pick_ups_id_seq'::regclass),
  "name" varchar COLLATE "pg_catalog"."default",
  "email" varchar COLLATE "pg_catalog"."default",
  "address" varchar COLLATE "pg_catalog"."default",
  "mobile" varchar COLLATE "pg_catalog"."default",
  "google_place_id" varchar COLLATE "pg_catalog"."default",
  "province_name" varchar COLLATE "pg_catalog"."default",
  "city_name" varchar COLLATE "pg_catalog"."default",
  "street" varchar COLLATE "pg_catalog"."default",
  "street_number" varchar COLLATE "pg_catalog"."default",
  "opening_hours" varchar COLLATE "pg_catalog"."default",
  "postal_code" varchar COLLATE "pg_catalog"."default",
  "latitude" float8,
  "longitude" float8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "store_id" int8,
  "weekdays" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "time_period" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "self_pick_orders_limit_every_day" int4 DEFAULT 0,
  "enabled" bool DEFAULT true,
  "support_same_day_delivery" bool DEFAULT false
)
;
COMMENT ON COLUMN "self_pick_ups"."opening_hours" IS '营业时间';

-- ----------------------------
-- Table structure for share_settings
-- ----------------------------
CREATE TABLE "share_settings" (
  "id" int8 NOT NULL DEFAULT nextval('share_settings_id_seq'::regclass),
  "share_background_cover" varchar COLLATE "pg_catalog"."default",
  "share_words" varchar COLLATE "pg_catalog"."default",
  "share_cover" varchar COLLATE "pg_catalog"."default",
  "target_type" varchar COLLATE "pg_catalog"."default",
  "target_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "store_id" int8,
  "search_words" varchar COLLATE "pg_catalog"."default",
  "search_cover" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for shopline_users
-- ----------------------------
CREATE TABLE "shopline_users" (
  "id" int8 NOT NULL DEFAULT nextval('shopline_users_id_seq'::regclass),
  "email" varchar COLLATE "pg_catalog"."default",
  "password_digest" varchar COLLATE "pg_catalog"."default",
  "phone" varchar COLLATE "pg_catalog"."default",
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "reset_password_token" varchar COLLATE "pg_catalog"."default",
  "reset_email_token" varchar COLLATE "pg_catalog"."default",
  "shopline_user_id" varchar COLLATE "pg_catalog"."default",
  "addresses" jsonb,
  "reset_phone_token" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for shopping_cart_items
-- ----------------------------
CREATE TABLE "shopping_cart_items" (
  "id" int8 NOT NULL DEFAULT nextval('shopping_cart_items_id_seq'::regclass),
  "quantity" int4 DEFAULT 1,
  "shopping_cart_id" int8,
  "stock_keeping_unit_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "deleted_at" timestamp(6),
  "store_id" int8,
  "source_page_name" int4,
  "source_channel" int4,
  "source_custom_list_id" int4,
  "source_extra_hash" json,
  "live_top" bool DEFAULT false
)
;
COMMENT ON COLUMN "shopping_cart_items"."live_top" IS '直播间置顶并免邮';

-- ----------------------------
-- Table structure for shopping_carts
-- ----------------------------
CREATE TABLE "shopping_carts" (
  "id" int8 NOT NULL DEFAULT nextval('shopping_carts_id_seq'::regclass),
  "user_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for shortened_scenes
-- ----------------------------
CREATE TABLE "shortened_scenes" (
  "id" int8 NOT NULL DEFAULT nextval('shortened_scenes_id_seq'::regclass),
  "scene" varchar COLLATE "pg_catalog"."default",
  "short_scene" varchar COLLATE "pg_catalog"."default",
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for sign_in_activities
-- ----------------------------
CREATE TABLE "sign_in_activities" (
  "id" int8 NOT NULL DEFAULT nextval('sign_in_activities_id_seq'::regclass),
  "detail_image" varchar COLLATE "pg_catalog"."default",
  "start_at" timestamp(6),
  "end_at" timestamp(6),
  "enabled" bool DEFAULT true,
  "reward_integral_each_time" int4,
  "extra_reward_type" int4 DEFAULT 1,
  "sign_in_times" int4,
  "extra_reward_integral" int4,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "banner" varchar COLLATE "pg_catalog"."default"
)
;
COMMENT ON COLUMN "sign_in_activities"."enabled" IS '是否启用';
COMMENT ON COLUMN "sign_in_activities"."reward_integral_each_time" IS '单次签到金币';
COMMENT ON COLUMN "sign_in_activities"."extra_reward_type" IS '额外奖励计算方式';
COMMENT ON COLUMN "sign_in_activities"."sign_in_times" IS '签到次数';
COMMENT ON COLUMN "sign_in_activities"."extra_reward_integral" IS '额外金币';

-- ----------------------------
-- Table structure for sign_in_activity_translations
-- ----------------------------
CREATE TABLE "sign_in_activity_translations" (
  "id" int8 NOT NULL DEFAULT nextval('sign_in_activity_translations_id_seq'::regclass),
  "sign_in_activity_id" int8 NOT NULL,
  "locale" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "title" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for sign_in_histories
-- ----------------------------
CREATE TABLE "sign_in_histories" (
  "id" int8 NOT NULL DEFAULT nextval('sign_in_histories_id_seq'::regclass),
  "sign_in_activity_id" int8,
  "user_id" int8,
  "sign_in_date" date,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for sign_in_reward_histories
-- ----------------------------
CREATE TABLE "sign_in_reward_histories" (
  "id" int8 NOT NULL DEFAULT nextval('sign_in_reward_histories_id_seq'::regclass),
  "sign_in_activity_id" int8,
  "sign_in_history_id" int8,
  "user_id" int8,
  "reward_type" int4 DEFAULT 1,
  "integral" int4,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for site_configs
-- ----------------------------
CREATE TABLE "site_configs" (
  "id" int8 NOT NULL DEFAULT nextval('site_configs_id_seq'::regclass),
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "customer_service_name" varchar COLLATE "pg_catalog"."default",
  "web_home_banners" json DEFAULT '[]'::json,
  "web_item_list_images" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "web_welcome_image" varchar COLLATE "pg_catalog"."default",
  "mall_tips" json,
  "direct_refund_reasons" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "after_sale_reasons" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "return_receiver_properties" json,
  "member_bg_image" varchar COLLATE "pg_catalog"."default",
  "order_analyses_notify_emails" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "order_configs" json DEFAULT '{}'::json,
  "web_item_list_video" json DEFAULT '{}'::json,
  "web_event_list_video" json DEFAULT '{}'::json,
  "web_welcome_video" json DEFAULT '{}'::json,
  "integral_rules" json DEFAULT '{}'::json,
  "payment_settings" json DEFAULT '{}'::json,
  "stock_short_quantity" int4,
  "android_sms_public_url" varchar COLLATE "pg_catalog"."default",
  "android_sms_notification_emails" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "watermark_attributes" json DEFAULT '{}'::json,
  "user_default_avatar" varchar COLLATE "pg_catalog"."default",
  "app_version" json,
  "config_type" int4 DEFAULT 1,
  "sms_first_phone_send_at" timestamp(6),
  "sms_second_phone_send_at" timestamp(6),
  "cutoff_time" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "store_id" int8,
  "base" json DEFAULT '{}'::json,
  "invited_coupon_template_id" int4,
  "newbie_coupon_template_ids" int4[] DEFAULT '{}'::integer[],
  "customer_services" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "merchant_delivery_orders_limit_every_day" int4 DEFAULT 0,
  "enable_commweb_3ds_auth" bool DEFAULT false,
  "merchant_delivery_total_orders_limit_every_day" int4 DEFAULT 0,
  "allow_comments" bool DEFAULT true,
  "cart_empty_image" varchar COLLATE "pg_catalog"."default",
  "order_creation_disabled" bool DEFAULT false,
  "order_creation_disabled_tips" varchar COLLATE "pg_catalog"."default",
  "finish_order_coupon_template_ids_to_inviter" int4[] DEFAULT '{}'::integer[],
  "delivery_type_settings" json DEFAULT '{}'::json,
  "search_placeholder" varchar COLLATE "pg_catalog"."default",
  "integral_special_period_rule" json DEFAULT '{}'::json,
  "order_buyer_message_placeholder" varchar COLLATE "pg_catalog"."default",
  "invitation" json DEFAULT '{}'::json,
  "sku_cost_minimum_factor" numeric NOT NULL DEFAULT 1.3,
  "sku_price_exception_emails" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "new_user_custom_page_id" int4,
  "new_user_message_text" text COLLATE "pg_catalog"."default",
  "invited_coupon_template_ids" int4[] DEFAULT '{}'::integer[],
  "order_finished_reward_integral" bool DEFAULT true,
  "custom_time_zone" varchar COLLATE "pg_catalog"."default",
  "sku_minimum_profit_in_cent" int4,
  "risk_pay_enabled" bool DEFAULT false,
  "same_day_delivery_cutoff_time" json DEFAULT '{}'::json,
  "info_finished_coupon_template_id" int4,
  "birthday_coupon_template_id" int4,
  "value_added_service_settings" json DEFAULT '{}'::json,
  "kuaima_delivery_max_count" int4 DEFAULT 0,
  "web_newbie_coupon_template_ids" int4[] DEFAULT '{}'::integer[],
  "web_invited_coupon_template_ids" int4[] DEFAULT '{}'::integer[],
  "web_finish_order_coupon_template_ids_to_inviter" int4[] DEFAULT '{}'::integer[],
  "web_info_finished_coupon_template_id" int4,
  "web_birthday_coupon_template_id" int4,
  "auction_enabled" bool DEFAULT true,
  "shopline_price_rate" numeric(10,2) DEFAULT 1.2,
  "shopline_order_creation_disabled" bool DEFAULT false,
  "bottom_settings" jsonb DEFAULT '{}'::jsonb,
  "payment_callback_timeout_emails" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "ae_sku_cost_minimum_factor" numeric NOT NULL DEFAULT 1.3,
  "ae_order_gst_percent" int4 DEFAULT 10,
  "go_back_to_ebest_right_icon_settings" jsonb DEFAULT '{}'::jsonb,
  "go_back_to_ebest_category_icon_settings" jsonb DEFAULT '{}'::jsonb,
  "go_back_to_ebest_bottom_icon_settings" jsonb DEFAULT '{}'::jsonb,
  "order_box_regulation_settings" jsonb DEFAULT '{}'::jsonb,
  "order_package_settings" jsonb DEFAULT '{}'::jsonb,
  "sms_platform" varchar COLLATE "pg_catalog"."default" NOT NULL DEFAULT 'nxcloud'::character varying
)
;
COMMENT ON COLUMN "site_configs"."merchant_delivery_orders_limit_every_day" IS '每日地址数配送上限';
COMMENT ON COLUMN "site_configs"."merchant_delivery_total_orders_limit_every_day" IS '每日总订单配送上限';
COMMENT ON COLUMN "site_configs"."value_added_service_settings" IS '增值服务开关配置';
COMMENT ON COLUMN "site_configs"."kuaima_delivery_max_count" IS '每天快马配送最大数量';
COMMENT ON COLUMN "site_configs"."auction_enabled" IS '控制APP我的拍卖入口显示';
COMMENT ON COLUMN "site_configs"."shopline_price_rate" IS 'Shopline价格倍率';
COMMENT ON COLUMN "site_configs"."go_back_to_ebest_right_icon_settings" IS '回到自营页右侧图标设置';
COMMENT ON COLUMN "site_configs"."go_back_to_ebest_category_icon_settings" IS '回到自营页分类图标设置';
COMMENT ON COLUMN "site_configs"."go_back_to_ebest_bottom_icon_settings" IS '回到自营页底部图标设置';
COMMENT ON COLUMN "site_configs"."sms_platform" IS '短信发送平台';

-- ----------------------------
-- Table structure for sku_groupons
-- ----------------------------
CREATE TABLE "sku_groupons" (
  "id" int8 NOT NULL DEFAULT nextval('sku_groupons_id_seq'::regclass),
  "stock_keeping_unit_id" int8,
  "groupon_activity_id" int8,
  "item_id" int8,
  "price_in_cent" int4,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "enabled" bool DEFAULT true
)
;
COMMENT ON COLUMN "sku_groupons"."price_in_cent" IS '商品拼团价格';

-- ----------------------------
-- Table structure for sku_in_stock_notices
-- ----------------------------
CREATE TABLE "sku_in_stock_notices" (
  "id" int8 NOT NULL DEFAULT nextval('sku_in_stock_notices_id_seq'::regclass),
  "user_id" int8,
  "stock_keeping_unit_id" int8,
  "state" int4 DEFAULT 0,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for sku_inventory_snapshots
-- ----------------------------
CREATE TABLE "sku_inventory_snapshots" (
  "id" int8 NOT NULL DEFAULT nextval('sku_inventory_snapshots_id_seq'::regclass),
  "stock_keeping_unit_id" int8,
  "record_date" date,
  "quantity" int4 DEFAULT 0,
  "reserved_quantity" int4 DEFAULT 0,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for sku_properties
-- ----------------------------
CREATE TABLE "sku_properties" (
  "id" int8 NOT NULL DEFAULT nextval('sku_properties_id_seq'::regclass),
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "ae_property_id" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for sku_property_translations
-- ----------------------------
CREATE TABLE "sku_property_translations" (
  "id" int8 NOT NULL DEFAULT nextval('sku_property_translations_id_seq'::regclass),
  "sku_property_id" int8 NOT NULL,
  "locale" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "text" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for sku_sales_mailer_settings
-- ----------------------------
CREATE TABLE "sku_sales_mailer_settings" (
  "id" int8 NOT NULL DEFAULT nextval('sku_sales_mailer_settings_id_seq'::regclass),
  "title" varchar COLLATE "pg_catalog"."default",
  "receiver_emails" varchar COLLATE "pg_catalog"."default",
  "cc_emails" varchar COLLATE "pg_catalog"."default",
  "deliver_after_n_days" int4,
  "contains_order_gift" bool,
  "contains_order_pool_gift" bool,
  "send_at" varchar COLLATE "pg_catalog"."default",
  "send_frequency" int4,
  "weekdays" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "sku_search_type" int4,
  "sku_search_conditions" json DEFAULT '{}'::json,
  "sku_ids" int4[] DEFAULT '{}'::integer[],
  "enabled" bool DEFAULT false,
  "store_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "skip_zero_sales_skus" bool DEFAULT true
)
;
COMMENT ON COLUMN "sku_sales_mailer_settings"."title" IS '邮件标题';
COMMENT ON COLUMN "sku_sales_mailer_settings"."receiver_emails" IS '接收邮件的邮箱，多个邮箱用分号分隔';
COMMENT ON COLUMN "sku_sales_mailer_settings"."cc_emails" IS '抄送邮件的邮箱，多个邮箱用分号分隔';
COMMENT ON COLUMN "sku_sales_mailer_settings"."deliver_after_n_days" IS 'N天后发货的统计，例：设置1则统计发货日期为一天后的数据';
COMMENT ON COLUMN "sku_sales_mailer_settings"."contains_order_gift" IS '是否包含订单赠品';
COMMENT ON COLUMN "sku_sales_mailer_settings"."contains_order_pool_gift" IS '是否包含订单池赠品';
COMMENT ON COLUMN "sku_sales_mailer_settings"."send_at" IS '发送时间，格式：HH:MM:SS';
COMMENT ON COLUMN "sku_sales_mailer_settings"."send_frequency" IS '发送频率，1: 单次，2: 每天，3: 每周';
COMMENT ON COLUMN "sku_sales_mailer_settings"."weekdays" IS '每周发送的日期，0: 周日, 1: 周一，2: 周二，3: 周三，4: 周四，5: 周五，6: 周六';
COMMENT ON COLUMN "sku_sales_mailer_settings"."sku_search_type" IS 'sku搜索类型，1: 根据条件，2: 根据sku_ids';
COMMENT ON COLUMN "sku_sales_mailer_settings"."sku_search_conditions" IS 'sku搜索条件';
COMMENT ON COLUMN "sku_sales_mailer_settings"."enabled" IS '是否启用';
COMMENT ON COLUMN "sku_sales_mailer_settings"."store_id" IS '店铺';
COMMENT ON COLUMN "sku_sales_mailer_settings"."skip_zero_sales_skus" IS '是否过滤掉销量为0的sku';

-- ----------------------------
-- Table structure for sku_valid_inventory_dates
-- ----------------------------
CREATE TABLE "sku_valid_inventory_dates" (
  "id" int8 NOT NULL DEFAULT nextval('sku_valid_inventory_dates_id_seq'::regclass),
  "stock_keeping_unit_id" int8,
  "date" date NOT NULL,
  "store_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for sku_value_translations
-- ----------------------------
CREATE TABLE "sku_value_translations" (
  "id" int8 NOT NULL DEFAULT nextval('sku_value_translations_id_seq'::regclass),
  "sku_value_id" int8 NOT NULL,
  "locale" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "text" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for sku_values
-- ----------------------------
CREATE TABLE "sku_values" (
  "id" int8 NOT NULL DEFAULT nextval('sku_values_id_seq'::regclass),
  "sku_property_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "ae_property_value_id" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for stock_keeping_units
-- ----------------------------
CREATE TABLE "stock_keeping_units" (
  "id" int8 NOT NULL DEFAULT nextval('stock_keeping_units_id_seq'::regclass),
  "properties" varchar COLLATE "pg_catalog"."default",
  "quantity" int4 DEFAULT 0,
  "price_in_cent" int4 DEFAULT 0,
  "image" varchar COLLATE "pg_catalog"."default",
  "position" int4 DEFAULT 0,
  "comments_count" int4 DEFAULT 0,
  "item_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "weight_in_gram" int4 NOT NULL DEFAULT 0,
  "cost_price_in_cent" int4 DEFAULT 0,
  "no" varchar COLLATE "pg_catalog"."default",
  "groups" json DEFAULT '[]'::json,
  "height_in_cm" float8 DEFAULT 0.0,
  "width_in_cm" float8 DEFAULT 0.0,
  "length_in_cm" float8 DEFAULT 0.0,
  "barcode" varchar COLLATE "pg_catalog"."default",
  "strikethrough_price_in_cent" int4,
  "on_sale" bool DEFAULT true,
  "store_id" int8,
  "carton_size" int4 DEFAULT 0,
  "pending_in_stock_notices_count" int4 DEFAULT 0,
  "gst_percent" int4 DEFAULT 0,
  "marketing_mode" int4 DEFAULT 1,
  "is_special" bool DEFAULT false,
  "shoppingunit" varchar COLLATE "pg_catalog"."default",
  "discount_quantity" int4,
  "discount_price_in_cent" int4,
  "new_user_price_in_cent" int4,
  "new_user_buy_quota" int4 DEFAULT 0,
  "sku_level" varchar COLLATE "pg_catalog"."default",
  "can_cover_weeks" int4,
  "can_create_invoice" bool DEFAULT true,
  "nominal_gross_margin_ratio" numeric(12,2) DEFAULT 0,
  "gmv_sku_level" varchar COLLATE "pg_catalog"."default",
  "gp_sku_level" varchar COLLATE "pg_catalog"."default",
  "turnover_rate" numeric(12,2),
  "first_sale_at" timestamp(6),
  "shopline_price_in_cent" int4 DEFAULT 0,
  "ae_price_in_cent" int4 DEFAULT 0,
  "aws_lambda_image_generated" bool DEFAULT false,
  "ae_sku_attr" varchar COLLATE "pg_catalog"."default",
  "is_box_regulation" bool DEFAULT false,
  "is_private_kitchen" bool DEFAULT false
)
;
COMMENT ON COLUMN "stock_keeping_units"."shoppingunit" IS '入驻商';
COMMENT ON COLUMN "stock_keeping_units"."new_user_buy_quota" IS '新人限购数量，0为不限';
COMMENT ON COLUMN "stock_keeping_units"."nominal_gross_margin_ratio" IS '名义毛利率';
COMMENT ON COLUMN "stock_keeping_units"."turnover_rate" IS '周转率';
COMMENT ON COLUMN "stock_keeping_units"."first_sale_at" IS '首次上架开卖时间';
COMMENT ON COLUMN "stock_keeping_units"."is_private_kitchen" IS '是否私厨';

-- ----------------------------
-- Table structure for stores
-- ----------------------------
CREATE TABLE "stores" (
  "id" int8 NOT NULL DEFAULT nextval('stores_id_seq'::regclass),
  "name" varchar COLLATE "pg_catalog"."default",
  "is_default" bool DEFAULT false,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "bg_color" varchar COLLATE "pg_catalog"."default" DEFAULT '#C5EDE7'::character varying,
  "short_name" varchar COLLATE "pg_catalog"."default",
  "default_au_suburb_id" int4,
  "disabled" bool DEFAULT false
)
;
COMMENT ON COLUMN "stores"."disabled" IS '是否停用门店';

-- ----------------------------
-- Table structure for subscribe_records
-- ----------------------------
CREATE TABLE "subscribe_records" (
  "id" int8 NOT NULL DEFAULT nextval('subscribe_records_id_seq'::regclass),
  "targetable_type" varchar COLLATE "pg_catalog"."default",
  "targetable_id" int8,
  "template_id" varchar COLLATE "pg_catalog"."default",
  "user_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for suppliers
-- ----------------------------
CREATE TABLE "suppliers" (
  "id" int8 NOT NULL DEFAULT nextval('suppliers_id_seq'::regclass),
  "name" varchar COLLATE "pg_catalog"."default",
  "cost_in_cent" int4,
  "stock_keeping_unit_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "include_gst" bool DEFAULT false,
  "gst_amount" numeric(12,2)
)
;

-- ----------------------------
-- Table structure for taggings
-- ----------------------------
CREATE TABLE "taggings" (
  "id" int4 NOT NULL DEFAULT nextval('taggings_id_seq'::regclass),
  "tag_id" int4,
  "taggable_type" varchar COLLATE "pg_catalog"."default",
  "taggable_id" int4,
  "tagger_type" varchar COLLATE "pg_catalog"."default",
  "tagger_id" int4,
  "context" varchar(128) COLLATE "pg_catalog"."default",
  "created_at" timestamp(6)
)
;

-- ----------------------------
-- Table structure for tags
-- ----------------------------
CREATE TABLE "tags" (
  "id" int4 NOT NULL DEFAULT nextval('tags_id_seq'::regclass),
  "name" varchar COLLATE "pg_catalog"."default",
  "taggings_count" int4 DEFAULT 0
)
;

-- ----------------------------
-- Table structure for third_party_categories
-- ----------------------------
CREATE TABLE "third_party_categories" (
  "id" int8 NOT NULL DEFAULT nextval('third_party_categories_id_seq'::regclass),
  "third_party_id" varchar COLLATE "pg_catalog"."default",
  "third_party_type" int4,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "category_id" int8
)
;
COMMENT ON COLUMN "third_party_categories"."third_party_type" IS '第三方平台类型: 1: shopline, 2: aliexpress';

-- ----------------------------
-- Table structure for third_party_items
-- ----------------------------
CREATE TABLE "third_party_items" (
  "id" int8 NOT NULL DEFAULT nextval('third_party_items_id_seq'::regclass),
  "item_id" int8,
  "third_party_id" varchar COLLATE "pg_catalog"."default",
  "third_party_type" int4,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;
COMMENT ON COLUMN "third_party_items"."third_party_type" IS '第三方平台类型: 1: shopline, 2: aliexpress';

-- ----------------------------
-- Table structure for third_party_orders
-- ----------------------------
CREATE TABLE "third_party_orders" (
  "id" int8 NOT NULL DEFAULT nextval('third_party_orders_id_seq'::regclass),
  "third_party_type" int4,
  "third_party_id" varchar COLLATE "pg_catalog"."default",
  "no" varchar COLLATE "pg_catalog"."default",
  "status" varchar COLLATE "pg_catalog"."default",
  "financial_status" varchar COLLATE "pg_catalog"."default",
  "fulfillment_status" varchar COLLATE "pg_catalog"."default",
  "delivery_type" int4 DEFAULT 1,
  "sync_status" int4 DEFAULT 1,
  "synced_at" timestamp(6),
  "delivery_date" varchar COLLATE "pg_catalog"."default",
  "prefer_time" varchar COLLATE "pg_catalog"."default",
  "order_total" numeric(10,2),
  "total_discounts" numeric(10,2),
  "total_line_items_price" numeric(10,2),
  "order_items" jsonb,
  "payment_details" jsonb DEFAULT '{}'::jsonb,
  "receiver_properties" jsonb NOT NULL DEFAULT '{}'::jsonb,
  "buyer_message" varchar COLLATE "pg_catalog"."default",
  "shipping_lines" jsonb NOT NULL DEFAULT '{}'::jsonb,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "store_id" int8,
  "warehouse_order_id" int8,
  "refunds" jsonb,
  "delivery_path" varchar COLLATE "pg_catalog"."default",
  "delivery_track" varchar COLLATE "pg_catalog"."default",
  "eta" timestamp(6),
  "ata" timestamp(6),
  "inventory_returned" bool DEFAULT false,
  "tracking_no" varchar COLLATE "pg_catalog"."default",
  "customer_id" varchar COLLATE "pg_catalog"."default"
)
;
COMMENT ON COLUMN "third_party_orders"."third_party_type" IS '第三方平台类型: 1: shopline, 2: aliexpress';
COMMENT ON COLUMN "third_party_orders"."third_party_id" IS '第三方平台订单id';
COMMENT ON COLUMN "third_party_orders"."no" IS '第三方平台订单号';
COMMENT ON COLUMN "third_party_orders"."status" IS '状态: open 处理中，cancelled 已取消';
COMMENT ON COLUMN "third_party_orders"."financial_status" IS '支付状态';
COMMENT ON COLUMN "third_party_orders"."fulfillment_status" IS '发货状态';
COMMENT ON COLUMN "third_party_orders"."sync_status" IS '同步到 wms 状态';
COMMENT ON COLUMN "third_party_orders"."synced_at" IS '同步到 wms 时间';
COMMENT ON COLUMN "third_party_orders"."delivery_date" IS '配送日期';
COMMENT ON COLUMN "third_party_orders"."prefer_time" IS '配送时间段';
COMMENT ON COLUMN "third_party_orders"."order_total" IS '订单支付金额';
COMMENT ON COLUMN "third_party_orders"."total_discounts" IS '折扣金额';
COMMENT ON COLUMN "third_party_orders"."total_line_items_price" IS '商品总价';
COMMENT ON COLUMN "third_party_orders"."order_items" IS '订单商品';
COMMENT ON COLUMN "third_party_orders"."payment_details" IS '支付详情';
COMMENT ON COLUMN "third_party_orders"."receiver_properties" IS '收货人信息';
COMMENT ON COLUMN "third_party_orders"."buyer_message" IS '买家留言';
COMMENT ON COLUMN "third_party_orders"."shipping_lines" IS '运费信息';
COMMENT ON COLUMN "third_party_orders"."delivery_path" IS '配送路线';
COMMENT ON COLUMN "third_party_orders"."delivery_track" IS '物流追踪';
COMMENT ON COLUMN "third_party_orders"."inventory_returned" IS '是否已回退库存';

-- ----------------------------
-- Table structure for third_party_skus
-- ----------------------------
CREATE TABLE "third_party_skus" (
  "id" int8 NOT NULL DEFAULT nextval('third_party_skus_id_seq'::regclass),
  "stock_keeping_unit_id" int8,
  "third_party_id" varchar COLLATE "pg_catalog"."default",
  "third_party_type" int4,
  "third_party_inventory_item_id" varchar COLLATE "pg_catalog"."default",
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;
COMMENT ON COLUMN "third_party_skus"."third_party_type" IS '第三方平台类型: 1: shopline, 2: aliexpress';
COMMENT ON COLUMN "third_party_skus"."third_party_inventory_item_id" IS '库存id';

-- ----------------------------
-- Table structure for third_party_users
-- ----------------------------
CREATE TABLE "third_party_users" (
  "id" int8 NOT NULL DEFAULT nextval('third_party_users_id_seq'::regclass),
  "third_party_type" int4,
  "third_party_id" varchar COLLATE "pg_catalog"."default",
  "email" varchar COLLATE "pg_catalog"."default",
  "store_id" int8,
  "first_name" varchar COLLATE "pg_catalog"."default",
  "last_name" varchar COLLATE "pg_catalog"."default",
  "nick_name" varchar COLLATE "pg_catalog"."default",
  "gender" varchar COLLATE "pg_catalog"."default",
  "phone" varchar COLLATE "pg_catalog"."default",
  "total_spent" varchar COLLATE "pg_catalog"."default",
  "orders_count" int4,
  "note" text COLLATE "pg_catalog"."default",
  "state" int4,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;
COMMENT ON COLUMN "third_party_users"."third_party_type" IS '第三方平台类型: 1: shopline, 2: aliexpress';
COMMENT ON COLUMN "third_party_users"."state" IS '0: 已禁用账户, 1: 待启用账户, 2: 已邀请账户, 3: 有效账户';

-- ----------------------------
-- Table structure for time_limited_promotion_prices
-- ----------------------------
CREATE TABLE "time_limited_promotion_prices" (
  "id" int8 NOT NULL DEFAULT nextval('time_limited_promotion_prices_id_seq'::regclass),
  "time_limited_promotion_id" int8,
  "stock_keeping_unit_id" int8,
  "price_in_cent" int4 NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "start_at" timestamp(6),
  "end_at" timestamp(6),
  "enabled" bool DEFAULT false,
  "store_id" int8,
  "quantity" int4,
  "reserved_quantity" int4,
  "original_buy_quota" int4 DEFAULT 0,
  "original_buy_quota_days" int4 DEFAULT 0,
  "buy_quota" int4 DEFAULT 0,
  "buy_quota_days" int4 DEFAULT 1,
  "quantity_updated_at" timestamp(6),
  "position" int4
)
;
COMMENT ON COLUMN "time_limited_promotion_prices"."quantity" IS '优惠价库存';
COMMENT ON COLUMN "time_limited_promotion_prices"."reserved_quantity" IS '预留的原价库存';
COMMENT ON COLUMN "time_limited_promotion_prices"."position" IS '权重，值越小，排序越靠前';

-- ----------------------------
-- Table structure for time_limited_promotions
-- ----------------------------
CREATE TABLE "time_limited_promotions" (
  "id" int8 NOT NULL DEFAULT nextval('time_limited_promotions_id_seq'::regclass),
  "title" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "start_at" timestamp(6) NOT NULL,
  "end_at" timestamp(6) NOT NULL,
  "enabled" bool DEFAULT false,
  "store_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "state" int4 NOT NULL DEFAULT 0,
  "save_qty_to_promotion_price" bool DEFAULT false
)
;
COMMENT ON COLUMN "time_limited_promotions"."save_qty_to_promotion_price" IS '限时优惠活动期间添加库存到优惠库存';

-- ----------------------------
-- Table structure for top_left_item_tags
-- ----------------------------
CREATE TABLE "top_left_item_tags" (
  "id" int8 NOT NULL DEFAULT nextval('top_left_item_tags_id_seq'::regclass),
  "name" varchar COLLATE "pg_catalog"."default",
  "icon" varchar COLLATE "pg_catalog"."default",
  "item_ids" int4[] DEFAULT '{}'::integer[],
  "start_at" timestamp(6),
  "end_at" timestamp(6),
  "store_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for user_histories
-- ----------------------------
CREATE TABLE "user_histories" (
  "id" int8 NOT NULL DEFAULT nextval('user_histories_id_seq'::regclass),
  "user_id" int8,
  "operatable_type" varchar COLLATE "pg_catalog"."default",
  "operatable_id" int8,
  "view_date" date,
  "count" int4 DEFAULT 0,
  "channel" int4 DEFAULT 1,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "deleted_at" timestamp(6)
)
;

-- ----------------------------
-- Table structure for user_recommended_products
-- ----------------------------
CREATE TABLE "user_recommended_products" (
  "id" int8 NOT NULL DEFAULT nextval('user_recommended_products_id_seq'::regclass),
  "user_id" int8,
  "mobile" varchar COLLATE "pg_catalog"."default",
  "recommended_products" text COLLATE "pg_catalog"."default",
  "wechat" varchar COLLATE "pg_catalog"."default",
  "images" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;
COMMENT ON COLUMN "user_recommended_products"."mobile" IS '手机号';
COMMENT ON COLUMN "user_recommended_products"."recommended_products" IS '推荐的商品';
COMMENT ON COLUMN "user_recommended_products"."wechat" IS '微信号';

-- ----------------------------
-- Table structure for user_suggestions
-- ----------------------------
CREATE TABLE "user_suggestions" (
  "id" int8 NOT NULL DEFAULT nextval('user_suggestions_id_seq'::regclass),
  "content" text COLLATE "pg_catalog"."default",
  "status" int4 DEFAULT 1,
  "user_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "channel" int4 DEFAULT 1,
  "reply" text COLLATE "pg_catalog"."default",
  "images" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "replied_at" timestamp(6)
)
;

-- ----------------------------
-- Table structure for users
-- ----------------------------
CREATE TABLE "users" (
  "id" int8 NOT NULL DEFAULT nextval('users_id_seq'::regclass),
  "nickname" varchar COLLATE "pg_catalog"."default",
  "avatar" varchar COLLATE "pg_catalog"."default",
  "mobile" varchar COLLATE "pg_catalog"."default",
  "open_id" varchar COLLATE "pg_catalog"."default",
  "gender" int4,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "valid_orders_count" int4 DEFAULT 0,
  "items_viewed_count" int4 NOT NULL DEFAULT 0,
  "session_key" varchar COLLATE "pg_catalog"."default",
  "new_user" bool DEFAULT true,
  "unionid" varchar COLLATE "pg_catalog"."default",
  "official_open_id" varchar COLLATE "pg_catalog"."default",
  "subscribe" bool,
  "app_open_id" varchar COLLATE "pg_catalog"."default",
  "ebest_platform_unionid" varchar COLLATE "pg_catalog"."default",
  "deleted_mini_open_id" varchar COLLATE "pg_catalog"."default",
  "is_blocked" bool DEFAULT false,
  "synce_from_fresh_at" timestamp(6),
  "origin_nickname" varchar COLLATE "pg_catalog"."default",
  "origin_gender" int4,
  "origin_avatar" varchar COLLATE "pg_catalog"."default",
  "selected_store_id" int8,
  "current_visit_ip" varchar COLLATE "pg_catalog"."default",
  "last_visit_ip" varchar COLLATE "pg_catalog"."default",
  "current_visit_at" timestamp(6),
  "last_visit_at" timestamp(6),
  "aus_mp_open_id" varchar COLLATE "pg_catalog"."default",
  "aus_mp_session_key" varchar COLLATE "pg_catalog"."default",
  "is_host" bool,
  "app_recent_item_search_words" text[] COLLATE "pg_catalog"."default" DEFAULT '{}'::text[],
  "deleted_by_user_at" timestamp(6),
  "locale" varchar COLLATE "pg_catalog"."default" DEFAULT 'zh-CN'::character varying,
  "is_overseas_student" bool DEFAULT false,
  "overseas_student_expiration_date" date,
  "password_digest" varchar COLLATE "pg_catalog"."default",
  "all_info_finished" bool DEFAULT false,
  "sign_up_channel" int4 DEFAULT 2,
  "guess_you_like_item_ids_hash" json DEFAULT '{}'::json,
  "web_recent_item_search_words" text[] COLLATE "pg_catalog"."default" DEFAULT '{}'::text[],
  "mini_program_recent_item_search_words" text[] COLLATE "pg_catalog"."default" DEFAULT '{}'::text[],
  "fingerprint_signatures" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "accept_marketing_message" bool DEFAULT true,
  "branch_io_campaign" varchar COLLATE "pg_catalog"."default",
  "branch_io_channel" varchar COLLATE "pg_catalog"."default",
  "branch_io_feature" varchar COLLATE "pg_catalog"."default",
  "branch_io_extra_hash" json,
  "app_version" varchar COLLATE "pg_catalog"."default"
)
;
COMMENT ON COLUMN "users"."official_open_id" IS '公众号 oepnid';
COMMENT ON COLUMN "users"."aus_mp_open_id" IS 'EBEST PTY LTD 主体小程序 Open ID';
COMMENT ON COLUMN "users"."aus_mp_session_key" IS 'EBEST PTY LTD 主体小程序 session key';
COMMENT ON COLUMN "users"."guess_you_like_item_ids_hash" IS '猜你喜欢的商品, 例: { "store-1-app": [1,2,3] }';
COMMENT ON COLUMN "users"."web_recent_item_search_words" IS 'Web最近搜索的商品关键词';
COMMENT ON COLUMN "users"."mini_program_recent_item_search_words" IS '小程序最近搜索的商品关键词';
COMMENT ON COLUMN "users"."fingerprint_signatures" IS '指纹签名';
COMMENT ON COLUMN "users"."accept_marketing_message" IS '是否接收营销短信';

-- ----------------------------
-- Table structure for users_push_messages
-- ----------------------------
CREATE TABLE "users_push_messages" (
  "id" int8 NOT NULL DEFAULT nextval('users_push_messages_id_seq'::regclass),
  "push_message_id" int8,
  "user_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for warehouse_orders
-- ----------------------------
CREATE TABLE "warehouse_orders" (
  "id" int8 NOT NULL DEFAULT nextval('warehouse_orders_id_seq'::regclass),
  "no" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "receiver_properties" jsonb NOT NULL DEFAULT '{}'::jsonb,
  "sync_status" int4 NOT NULL DEFAULT 2,
  "delivery_type" int4 NOT NULL,
  "delivery_date" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "user_id" int8,
  "delivery_track" varchar COLLATE "pg_catalog"."default",
  "prefer_time" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "deliver_to_door" bool NOT NULL,
  "authority_to_leave" bool NOT NULL,
  "buyer_message" varchar COLLATE "pg_catalog"."default",
  "remark" varchar COLLATE "pg_catalog"."default",
  "store_id" int8,
  "channel" int4,
  "express_carrier" varchar COLLATE "pg_catalog"."default",
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "same_day_delivery" bool DEFAULT false,
  "delivery_time_period_setting_id" int4
)
;
COMMENT ON COLUMN "warehouse_orders"."no" IS '仓储订单号，W开头';
COMMENT ON COLUMN "warehouse_orders"."receiver_properties" IS '收货人信息';
COMMENT ON COLUMN "warehouse_orders"."sync_status" IS '同步到 wms 状态';
COMMENT ON COLUMN "warehouse_orders"."delivery_type" IS '配送方式';
COMMENT ON COLUMN "warehouse_orders"."delivery_date" IS '配送日期';
COMMENT ON COLUMN "warehouse_orders"."delivery_track" IS '配送物流 URL';
COMMENT ON COLUMN "warehouse_orders"."prefer_time" IS '配送时间段';
COMMENT ON COLUMN "warehouse_orders"."deliver_to_door" IS '是否送货上门';
COMMENT ON COLUMN "warehouse_orders"."authority_to_leave" IS '是否无人签收';
COMMENT ON COLUMN "warehouse_orders"."buyer_message" IS '买家备注，多个销售订单买家备注拼接';
COMMENT ON COLUMN "warehouse_orders"."remark" IS '卖家备注，多个销售订单卖家备注拼接';
COMMENT ON COLUMN "warehouse_orders"."channel" IS '订单渠道';
COMMENT ON COLUMN "warehouse_orders"."express_carrier" IS '第三方邮寄派送，例如：KUAIMA';

-- ----------------------------
-- Table structure for web_banner_items
-- ----------------------------
CREATE TABLE "web_banner_items" (
  "id" int8 NOT NULL DEFAULT nextval('web_banner_items_id_seq'::regclass),
  "web_banner_id" int8,
  "position" int4 NOT NULL DEFAULT 1,
  "mobile_image_url" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "desktop_image_url" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "start_at" timestamp(6),
  "end_at" timestamp(6),
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "nav_path_type" varchar COLLATE "pg_catalog"."default",
  "nav_path_id" int8,
  "nav_path" json
)
;

-- ----------------------------
-- Table structure for web_banners
-- ----------------------------
CREATE TABLE "web_banners" (
  "id" int8 NOT NULL DEFAULT nextval('web_banners_id_seq'::regclass),
  "page_location" int4 NOT NULL,
  "remark" varchar COLLATE "pg_catalog"."default",
  "displayed" bool DEFAULT false,
  "store_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for web_categories
-- ----------------------------
CREATE TABLE "web_categories" (
  "id" int8 NOT NULL DEFAULT nextval('web_categories_id_seq'::regclass),
  "parent_id" int8,
  "status" int4 NOT NULL DEFAULT 1,
  "position" int4 NOT NULL DEFAULT 0,
  "icon" varchar COLLATE "pg_catalog"."default",
  "bg_color" varchar COLLATE "pg_catalog"."default",
  "display_length" int4 DEFAULT 5,
  "filter_icon" varchar COLLATE "pg_catalog"."default",
  "can_create_invoice" bool DEFAULT true,
  "sort_item_ids" int4[] DEFAULT '{}'::integer[],
  "need_age_verification" bool DEFAULT false,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "search_keywords" text COLLATE "pg_catalog"."default"
)
;
COMMENT ON COLUMN "web_categories"."search_keywords" IS '搜索关键词, 用于提升搜索商品准确度';

-- ----------------------------
-- Table structure for web_category_translations
-- ----------------------------
CREATE TABLE "web_category_translations" (
  "id" int8 NOT NULL DEFAULT nextval('web_category_translations_id_seq'::regclass),
  "web_category_id" int8 NOT NULL,
  "locale" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "name" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for web_custom_list_items
-- ----------------------------
CREATE TABLE "web_custom_list_items" (
  "id" int8 NOT NULL DEFAULT nextval('web_custom_list_items_id_seq'::regclass),
  "web_custom_list_id" int8,
  "item_id" int8,
  "position" int4,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL
)
;

-- ----------------------------
-- Table structure for web_custom_list_translations
-- ----------------------------
CREATE TABLE "web_custom_list_translations" (
  "id" int8 NOT NULL DEFAULT nextval('web_custom_list_translations_id_seq'::regclass),
  "web_custom_list_id" int8 NOT NULL,
  "locale" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "title" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Table structure for web_custom_lists
-- ----------------------------
CREATE TABLE "web_custom_lists" (
  "id" int8 NOT NULL DEFAULT nextval('web_custom_lists_id_seq'::regclass),
  "position" int4 DEFAULT 1,
  "displayed" bool DEFAULT false,
  "items_shuffled" bool DEFAULT false,
  "store_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "page_location" int4 NOT NULL DEFAULT 1,
  "orientation" int4 NOT NULL DEFAULT 1
)
;
COMMENT ON COLUMN "web_custom_lists"."orientation" IS '1: 横向, 2: 竖向';

-- ----------------------------
-- Table structure for web_items
-- ----------------------------
CREATE TABLE "web_items" (
  "id" int8 NOT NULL DEFAULT nextval('web_items_id_seq'::regclass),
  "upper_images" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "lower_images" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "banner_images" varchar[] COLLATE "pg_catalog"."default" DEFAULT '{}'::character varying[],
  "item_id" int8,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "video" json DEFAULT '{}'::json
)
;

-- ----------------------------
-- Table structure for wms_inventories
-- ----------------------------
CREATE TABLE "wms_inventories" (
  "id" int8 NOT NULL DEFAULT nextval('wms_inventories_id_seq'::regclass),
  "store_id" int4,
  "product_id" int4,
  "jerry_sku_id" int4,
  "inventory_type" int4,
  "area" varchar COLLATE "pg_catalog"."default",
  "location" varchar COLLATE "pg_catalog"."default",
  "expiry_date" timestamp(6),
  "qty" int4,
  "updated_at" timestamp(6)
)
;

-- ----------------------------
-- Indexes structure for table actions
-- ----------------------------
CREATE INDEX "index_actions_on_target_type_and_target_id_and_action_type" ON "actions" USING btree (
  "target_type" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST,
  "target_id" "pg_catalog"."int4_ops" ASC NULLS LAST,
  "action_type" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_actions_on_user_type_and_user_id_and_action_type" ON "actions" USING btree (
  "user_type" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST,
  "user_id" "pg_catalog"."int4_ops" ASC NULLS LAST,
  "action_type" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table actions
-- ----------------------------
ALTER TABLE "actions" ADD CONSTRAINT "actions_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table addresses
-- ----------------------------
CREATE INDEX "idx_addr_default_latest" ON "addresses" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "updated_at" "pg_catalog"."timestamp_ops" DESC NULLS FIRST
) WHERE is_default = true;
CREATE INDEX "index_addresses_on_user_id" ON "addresses" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table addresses
-- ----------------------------
ALTER TABLE "addresses" ADD CONSTRAINT "addresses_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table admin_assign_integral_records
-- ----------------------------
CREATE INDEX "index_admin_assign_integral_records_on_admin_user_id" ON "admin_assign_integral_records" USING btree (
  "admin_user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_admin_assign_integral_records_on_member_id" ON "admin_assign_integral_records" USING btree (
  "member_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_admin_assign_integral_records_on_store_id" ON "admin_assign_integral_records" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table admin_assign_integral_records
-- ----------------------------
ALTER TABLE "admin_assign_integral_records" ADD CONSTRAINT "admin_assign_integral_records_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table admin_user_stores
-- ----------------------------
CREATE INDEX "index_admin_user_stores_on_admin_user_id" ON "admin_user_stores" USING btree (
  "admin_user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_admin_user_stores_on_store_id" ON "admin_user_stores" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table admin_user_stores
-- ----------------------------
ALTER TABLE "admin_user_stores" ADD CONSTRAINT "admin_user_stores_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table admin_users
-- ----------------------------
CREATE INDEX "index_admin_users_on_creator_id" ON "admin_users" USING btree (
  "creator_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_admin_users_on_mobile" ON "admin_users" USING btree (
  "mobile" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_admin_users_on_role_template_id" ON "admin_users" USING btree (
  "role_template_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table admin_users
-- ----------------------------
ALTER TABLE "admin_users" ADD CONSTRAINT "admin_users_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table ae_categories
-- ----------------------------
CREATE INDEX "index_ae_categories_on_ae_id" ON "ae_categories" USING btree (
  "ae_id" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table ae_categories
-- ----------------------------
ALTER TABLE "ae_categories" ADD CONSTRAINT "ae_categories_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table ae_drop_shipper_orders
-- ----------------------------
CREATE INDEX "index_ae_drop_shipper_orders_on_order_id" ON "ae_drop_shipper_orders" USING btree (
  "order_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table ae_drop_shipper_orders
-- ----------------------------
ALTER TABLE "ae_drop_shipper_orders" ADD CONSTRAINT "ae_drop_shipper_orders_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table after_sales
-- ----------------------------
CREATE INDEX "index_after_sales_on_lastest_operator_id" ON "after_sales" USING btree (
  "lastest_operator_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_after_sales_on_order_id" ON "after_sales" USING btree (
  "order_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "index_after_sales_on_refund_no" ON "after_sales" USING btree (
  "refund_no" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_after_sales_on_store_id" ON "after_sales" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_after_sales_on_user_id" ON "after_sales" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table after_sales
-- ----------------------------
ALTER TABLE "after_sales" ADD CONSTRAINT "after_sales_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table after_sales_order_items
-- ----------------------------
CREATE INDEX "index_after_sales_order_items_on_after_sale_id" ON "after_sales_order_items" USING btree (
  "after_sale_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_after_sales_order_items_on_order_item_id" ON "after_sales_order_items" USING btree (
  "order_item_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table after_sales_order_items
-- ----------------------------
ALTER TABLE "after_sales_order_items" ADD CONSTRAINT "after_sales_order_items_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table age_verification_translations
-- ----------------------------
CREATE INDEX "index_age_verification_translations_on_age_verification_id" ON "age_verification_translations" USING btree (
  "age_verification_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_age_verification_translations_on_locale" ON "age_verification_translations" USING btree (
  "locale" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table age_verification_translations
-- ----------------------------
ALTER TABLE "age_verification_translations" ADD CONSTRAINT "age_verification_translations_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table age_verifications
-- ----------------------------
CREATE INDEX "index_age_verifications_on_parent_category_id" ON "age_verifications" USING btree (
  "parent_category_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_age_verifications_on_parent_web_category_id" ON "age_verifications" USING btree (
  "parent_web_category_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table age_verifications
-- ----------------------------
ALTER TABLE "age_verifications" ADD CONSTRAINT "age_verifications_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table app_download_channels
-- ----------------------------
ALTER TABLE "app_download_channels" ADD CONSTRAINT "app_download_channels_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table app_text_messages
-- ----------------------------
CREATE INDEX "index_app_text_messages_on_admin_user_id" ON "app_text_messages" USING btree (
  "admin_user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_app_text_messages_on_target_attrs" ON "app_text_messages" USING btree (
  "target_id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "target_type" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_app_text_messages_on_user_id" ON "app_text_messages" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table app_text_messages
-- ----------------------------
ALTER TABLE "app_text_messages" ADD CONSTRAINT "app_text_messages_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table ar_internal_metadata
-- ----------------------------
ALTER TABLE "ar_internal_metadata" ADD CONSTRAINT "ar_internal_metadata_pkey" PRIMARY KEY ("key");

-- ----------------------------
-- Indexes structure for table au_suburb_freight_templates
-- ----------------------------
CREATE INDEX "index_au_suburb_freight_templates_on_au_suburb_id" ON "au_suburb_freight_templates" USING btree (
  "au_suburb_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_au_suburb_freight_templates_on_freight_template_id" ON "au_suburb_freight_templates" USING btree (
  "freight_template_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table au_suburb_freight_templates
-- ----------------------------
ALTER TABLE "au_suburb_freight_templates" ADD CONSTRAINT "au_suburb_freight_templates_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table au_suburbs
-- ----------------------------
CREATE INDEX "index_au_suburbs_on_name" ON "au_suburbs" USING btree (
  "name" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_au_suburbs_on_postal_code" ON "au_suburbs" USING btree (
  "postal_code" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_au_suburbs_on_store_id" ON "au_suburbs" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table au_suburbs
-- ----------------------------
ALTER TABLE "au_suburbs" ADD CONSTRAINT "au_suburbs_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table auction_activities
-- ----------------------------
CREATE INDEX "index_auction_activities_on_best_automatic_bid_id" ON "auction_activities" USING btree (
  "best_automatic_bid_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_auction_activities_on_best_bid_id" ON "auction_activities" USING btree (
  "best_bid_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_auction_activities_on_brand_id" ON "auction_activities" USING btree (
  "brand_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_auction_activities_on_category_id" ON "auction_activities" USING btree (
  "category_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_auction_activities_on_item_id" ON "auction_activities" USING btree (
  "item_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_auction_activities_on_minor_category_id" ON "auction_activities" USING btree (
  "minor_category_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_auction_activities_on_minor_parent_category_id" ON "auction_activities" USING btree (
  "minor_parent_category_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "index_auction_activities_on_no" ON "auction_activities" USING btree (
  "no" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_auction_activities_on_order_id" ON "auction_activities" USING btree (
  "order_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_auction_activities_on_parent_category_id" ON "auction_activities" USING btree (
  "parent_category_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_auction_activities_on_qa_and_guarantee_id" ON "auction_activities" USING btree (
  "qa_and_guarantee_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_auction_activities_on_stock_keeping_unit_id" ON "auction_activities" USING btree (
  "stock_keeping_unit_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_auction_activities_on_store_id" ON "auction_activities" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table auction_activities
-- ----------------------------
ALTER TABLE "auction_activities" ADD CONSTRAINT "auction_activities_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table auction_activity_participations
-- ----------------------------
CREATE UNIQUE INDEX "index_activity_participations_on_user_id_and_activity_id" ON "auction_activity_participations" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "auction_activity_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_auction_activity_participations_on_auction_activity_id" ON "auction_activity_participations" USING btree (
  "auction_activity_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_auction_activity_participations_on_auction_order_id" ON "auction_activity_participations" USING btree (
  "auction_order_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_auction_activity_participations_on_store_id" ON "auction_activity_participations" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_auction_activity_participations_on_user_id" ON "auction_activity_participations" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table auction_activity_participations
-- ----------------------------
ALTER TABLE "auction_activity_participations" ADD CONSTRAINT "auction_activity_participations_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table auction_activity_translations
-- ----------------------------
CREATE INDEX "index_auction_activity_translations_on_auction_activity_id" ON "auction_activity_translations" USING btree (
  "auction_activity_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_auction_activity_translations_on_locale" ON "auction_activity_translations" USING btree (
  "locale" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table auction_activity_translations
-- ----------------------------
ALTER TABLE "auction_activity_translations" ADD CONSTRAINT "auction_activity_translations_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table auction_automatic_bids
-- ----------------------------
CREATE INDEX "index_auction_automatic_bids_on_auction_activity_id" ON "auction_automatic_bids" USING btree (
  "auction_activity_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_auction_automatic_bids_on_user_id" ON "auction_automatic_bids" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "index_automatic_bids_on_auction_activity_id_and_amount_limit" ON "auction_automatic_bids" USING btree (
  "auction_activity_id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "amount_limit_in_cent" "pg_catalog"."int4_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table auction_automatic_bids
-- ----------------------------
ALTER TABLE "auction_automatic_bids" ADD CONSTRAINT "auction_automatic_bids_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table auction_bids
-- ----------------------------
CREATE INDEX "index_auction_bids_on_auction_activity_id" ON "auction_bids" USING btree (
  "auction_activity_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "index_auction_bids_on_auction_activity_id_and_amount_in_cent" ON "auction_bids" USING btree (
  "auction_activity_id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "amount_in_cent" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "index_auction_bids_on_member_id" ON "auction_bids" USING btree (
  "member_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_auction_bids_on_user_id" ON "auction_bids" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table auction_bids
-- ----------------------------
ALTER TABLE "auction_bids" ADD CONSTRAINT "auction_bids_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table banner_clicks
-- ----------------------------
CREATE UNIQUE INDEX "index_banner_clicks_on_url_and_date" ON "banner_clicks" USING btree (
  "url" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST,
  "date" "pg_catalog"."date_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table banner_clicks
-- ----------------------------
ALTER TABLE "banner_clicks" ADD CONSTRAINT "banner_clicks_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table brand_translations
-- ----------------------------
CREATE INDEX "index_brand_translations_on_brand_id" ON "brand_translations" USING btree (
  "brand_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_brand_translations_on_locale" ON "brand_translations" USING btree (
  "locale" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table brand_translations
-- ----------------------------
ALTER TABLE "brand_translations" ADD CONSTRAINT "brand_translations_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table brands
-- ----------------------------
ALTER TABLE "brands" ADD CONSTRAINT "brands_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table categories
-- ----------------------------
CREATE INDEX "index_categories_on_ae_drop_shipper_category_id" ON "categories" USING btree (
  "ae_drop_shipper_category_id" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_categories_on_parent_id" ON "categories" USING btree (
  "parent_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table categories
-- ----------------------------
ALTER TABLE "categories" ADD CONSTRAINT "categories_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table category_translations
-- ----------------------------
CREATE INDEX "index_category_translations_on_category_id" ON "category_translations" USING btree (
  "category_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_category_translations_on_locale" ON "category_translations" USING btree (
  "locale" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table category_translations
-- ----------------------------
ALTER TABLE "category_translations" ADD CONSTRAINT "category_translations_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table cities
-- ----------------------------
CREATE INDEX "index_cities_on_province_id" ON "cities" USING btree (
  "province_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table cities
-- ----------------------------
ALTER TABLE "cities" ADD CONSTRAINT "cities_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table comments
-- ----------------------------
CREATE INDEX "index_comments_on_commentable_type_and_commentable_id" ON "comments" USING btree (
  "commentable_type" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST,
  "commentable_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "index_comments_on_deleted_at" ON "comments" USING btree (
  "deleted_at" "pg_catalog"."timestamp_ops" ASC NULLS LAST
);
CREATE INDEX "index_comments_on_item_id" ON "comments" USING btree (
  "item_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_comments_on_user_id" ON "comments" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table comments
-- ----------------------------
ALTER TABLE "comments" ADD CONSTRAINT "comments_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table counties
-- ----------------------------
CREATE INDEX "index_counties_on_city_id" ON "counties" USING btree (
  "city_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table counties
-- ----------------------------
ALTER TABLE "counties" ADD CONSTRAINT "counties_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table coupon_auto_assignments
-- ----------------------------
ALTER TABLE "coupon_auto_assignments" ADD CONSTRAINT "coupon_auto_assignments_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table coupon_packages
-- ----------------------------
CREATE INDEX "index_coupon_packages_on_store_id" ON "coupon_packages" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table coupon_packages
-- ----------------------------
ALTER TABLE "coupon_packages" ADD CONSTRAINT "coupon_packages_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table coupon_packages_users
-- ----------------------------
CREATE INDEX "index_coupon_packages_users_on_coupon_package_id" ON "coupon_packages_users" USING btree (
  "coupon_package_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "index_coupon_packages_users_on_user_id" ON "coupon_packages_users" USING btree (
  "user_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "index_coupon_packages_users_on_user_id_and_coupon_package_id" ON "coupon_packages_users" USING btree (
  "user_id" "pg_catalog"."int4_ops" ASC NULLS LAST,
  "coupon_package_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);

-- ----------------------------
-- Indexes structure for table coupon_template_translations
-- ----------------------------
CREATE INDEX "index_coupon_template_translations_on_coupon_template_id" ON "coupon_template_translations" USING btree (
  "coupon_template_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_coupon_template_translations_on_locale" ON "coupon_template_translations" USING btree (
  "locale" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table coupon_template_translations
-- ----------------------------
ALTER TABLE "coupon_template_translations" ADD CONSTRAINT "coupon_template_translations_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table coupon_templates
-- ----------------------------
CREATE INDEX "index_coupon_templates_on_store_id" ON "coupon_templates" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table coupon_templates
-- ----------------------------
ALTER TABLE "coupon_templates" ADD CONSTRAINT "coupon_templates_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table coupons
-- ----------------------------
CREATE INDEX "index_coupons_on_coupon_template_id" ON "coupons" USING btree (
  "coupon_template_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_coupons_on_coupon_template_id_and_status" ON "coupons" USING btree (
  "coupon_template_id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "status" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "index_coupons_on_invitee_id" ON "coupons" USING btree (
  "invitee_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_coupons_on_store_id" ON "coupons" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_coupons_on_user_id" ON "coupons" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table coupons
-- ----------------------------
ALTER TABLE "coupons" ADD CONSTRAINT "coupons_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table custom_list_items
-- ----------------------------
CREATE INDEX "index_custom_list_items_on_custom_list_id" ON "custom_list_items" USING btree (
  "custom_list_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_custom_list_items_on_item_id" ON "custom_list_items" USING btree (
  "item_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "index_custom_list_items_on_item_id_and_custom_list_id" ON "custom_list_items" USING btree (
  "item_id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "custom_list_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_custom_list_items_on_store_id" ON "custom_list_items" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table custom_list_items
-- ----------------------------
ALTER TABLE "custom_list_items" ADD CONSTRAINT "custom_list_items_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table custom_list_translations
-- ----------------------------
CREATE INDEX "index_custom_list_translations_on_custom_list_id" ON "custom_list_translations" USING btree (
  "custom_list_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_custom_list_translations_on_locale" ON "custom_list_translations" USING btree (
  "locale" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table custom_list_translations
-- ----------------------------
ALTER TABLE "custom_list_translations" ADD CONSTRAINT "custom_list_translations_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table custom_lists
-- ----------------------------
CREATE INDEX "index_custom_lists_on_parent_category_id" ON "custom_lists" USING btree (
  "parent_category_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "index_custom_lists_on_store_id" ON "custom_lists" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table custom_lists
-- ----------------------------
ALTER TABLE "custom_lists" ADD CONSTRAINT "custom_lists_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table custom_pages
-- ----------------------------
CREATE INDEX "index_custom_pages_on_creator_id" ON "custom_pages" USING btree (
  "creator_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_custom_pages_on_store_id" ON "custom_pages" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table custom_pages
-- ----------------------------
ALTER TABLE "custom_pages" ADD CONSTRAINT "custom_pages_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table cutoff_times
-- ----------------------------
CREATE INDEX "index_cutoff_times_on_item_id" ON "cutoff_times" USING btree (
  "item_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table cutoff_times
-- ----------------------------
ALTER TABLE "cutoff_times" ADD CONSTRAINT "cutoff_times_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table delivery_areas
-- ----------------------------
CREATE INDEX "index_delivery_areas_on_au_suburb_id" ON "delivery_areas" USING btree (
  "au_suburb_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "index_delivery_areas_on_delivery_time_id" ON "delivery_areas" USING btree (
  "delivery_time_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_delivery_areas_on_same_day_delivery_time_id" ON "delivery_areas" USING btree (
  "same_day_delivery_time_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table delivery_areas
-- ----------------------------
ALTER TABLE "delivery_areas" ADD CONSTRAINT "delivery_areas_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table delivery_time_order_date_analyses
-- ----------------------------
CREATE UNIQUE INDEX "delivery_time_order_on_delivery_date_and_delivery_time" ON "delivery_time_order_date_analyses" USING btree (
  "delivery_date" "pg_catalog"."date_ops" ASC NULLS LAST,
  "delivery_time_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table delivery_time_order_date_analyses
-- ----------------------------
ALTER TABLE "delivery_time_order_date_analyses" ADD CONSTRAINT "delivery_time_order_date_analyses_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table delivery_time_period_settings
-- ----------------------------
CREATE INDEX "index_delivery_time_period_settings_on_delivery_time_id" ON "delivery_time_period_settings" USING btree (
  "delivery_time_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_delivery_time_period_settings_on_delivery_time_period_id" ON "delivery_time_period_settings" USING btree (
  "delivery_time_period_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table delivery_time_period_settings
-- ----------------------------
ALTER TABLE "delivery_time_period_settings" ADD CONSTRAINT "delivery_time_period_settings_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table delivery_time_period_translations
-- ----------------------------
CREATE INDEX "index_22a0ee9988abd378953035bab7fb8eb026926fa8" ON "delivery_time_period_translations" USING btree (
  "delivery_time_period_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_delivery_time_period_translations_on_locale" ON "delivery_time_period_translations" USING btree (
  "locale" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table delivery_time_period_translations
-- ----------------------------
ALTER TABLE "delivery_time_period_translations" ADD CONSTRAINT "delivery_time_period_translations_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table delivery_time_periods
-- ----------------------------
CREATE INDEX "index_delivery_time_periods_on_delivery_time_id" ON "delivery_time_periods" USING btree (
  "delivery_time_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table delivery_time_periods
-- ----------------------------
ALTER TABLE "delivery_time_periods" ADD CONSTRAINT "delivery_time_periods_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table delivery_times
-- ----------------------------
ALTER TABLE "delivery_times" ADD CONSTRAINT "delivery_times_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table event_form_records
-- ----------------------------
CREATE INDEX "index_event_form_records_on_event_page_id" ON "event_form_records" USING btree (
  "event_page_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_event_form_records_on_event_slug" ON "event_form_records" USING btree (
  "event_slug" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_event_form_records_on_user_id" ON "event_form_records" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table event_form_records
-- ----------------------------
ALTER TABLE "event_form_records" ADD CONSTRAINT "event_form_records_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table event_pages
-- ----------------------------
ALTER TABLE "event_pages" ADD CONSTRAINT "event_pages_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table external_links
-- ----------------------------
ALTER TABLE "external_links" ADD CONSTRAINT "external_links_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table external_mini_programs
-- ----------------------------
ALTER TABLE "external_mini_programs" ADD CONSTRAINT "external_mini_programs_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table extra_orders_limits
-- ----------------------------
CREATE INDEX "index_extra_orders_limits_on_store_id" ON "extra_orders_limits" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "index_extra_orders_limits_on_store_id_and_delivery_date" ON "extra_orders_limits" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "delivery_date" "pg_catalog"."date_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table extra_orders_limits
-- ----------------------------
ALTER TABLE "extra_orders_limits" ADD CONSTRAINT "extra_orders_limits_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table form_item_applications
-- ----------------------------
CREATE INDEX "index_form_item_applications_on_form_item_id" ON "form_item_applications" USING btree (
  "form_item_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_form_item_applications_on_store_id" ON "form_item_applications" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_form_item_applications_on_user_id" ON "form_item_applications" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table form_item_applications
-- ----------------------------
ALTER TABLE "form_item_applications" ADD CONSTRAINT "form_item_applications_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table form_item_translations
-- ----------------------------
CREATE INDEX "index_form_item_translations_on_form_item_id" ON "form_item_translations" USING btree (
  "form_item_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_form_item_translations_on_locale" ON "form_item_translations" USING btree (
  "locale" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table form_item_translations
-- ----------------------------
ALTER TABLE "form_item_translations" ADD CONSTRAINT "form_item_translations_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table form_items
-- ----------------------------
CREATE INDEX "index_form_items_on_category_id" ON "form_items" USING btree (
  "category_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_form_items_on_minor_category_id" ON "form_items" USING btree (
  "minor_category_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "index_form_items_on_parent_category_id" ON "form_items" USING btree (
  "parent_category_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "index_form_items_on_store_id" ON "form_items" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table form_items
-- ----------------------------
ALTER TABLE "form_items" ADD CONSTRAINT "form_items_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table freight_template_translations
-- ----------------------------
CREATE INDEX "index_freight_template_translations_on_freight_template_id" ON "freight_template_translations" USING btree (
  "freight_template_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_freight_template_translations_on_locale" ON "freight_template_translations" USING btree (
  "locale" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table freight_template_translations
-- ----------------------------
ALTER TABLE "freight_template_translations" ADD CONSTRAINT "freight_template_translations_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table freight_templates
-- ----------------------------
CREATE INDEX "index_freight_templates_on_freight_template_id" ON "freight_templates" USING btree (
  "freight_template_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_freight_templates_on_store_id" ON "freight_templates" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table freight_templates
-- ----------------------------
ALTER TABLE "freight_templates" ADD CONSTRAINT "freight_templates_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table freight_templates_items
-- ----------------------------
CREATE INDEX "index_freight_templates_items_on_freight_template_id" ON "freight_templates_items" USING btree (
  "freight_template_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_freight_templates_items_on_item_id" ON "freight_templates_items" USING btree (
  "item_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Indexes structure for table gift_activities
-- ----------------------------
CREATE INDEX "index_gift_activities_on_store_id" ON "gift_activities" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table gift_activities
-- ----------------------------
ALTER TABLE "gift_activities" ADD CONSTRAINT "gift_activities_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table gift_card_coupons
-- ----------------------------
CREATE INDEX "index_gift_card_coupons_on_gift_card_template_id" ON "gift_card_coupons" USING btree (
  "gift_card_template_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table gift_card_coupons
-- ----------------------------
ALTER TABLE "gift_card_coupons" ADD CONSTRAINT "gift_card_coupons_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table gift_card_templates
-- ----------------------------
ALTER TABLE "gift_card_templates" ADD CONSTRAINT "gift_card_templates_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table groupon_activities
-- ----------------------------
CREATE INDEX "index_groupon_activities_on_item_id" ON "groupon_activities" USING btree (
  "item_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_groupon_activities_on_store_id" ON "groupon_activities" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table groupon_activities
-- ----------------------------
ALTER TABLE "groupon_activities" ADD CONSTRAINT "groupon_activities_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table groupons
-- ----------------------------
CREATE INDEX "index_groupons_on_creator_id" ON "groupons" USING btree (
  "creator_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_groupons_on_groupon_activity_id" ON "groupons" USING btree (
  "groupon_activity_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_groupons_on_sku_groupon_id" ON "groupons" USING btree (
  "sku_groupon_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_groupons_on_store_id" ON "groupons" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table groupons
-- ----------------------------
ALTER TABLE "groupons" ADD CONSTRAINT "groupons_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table histories
-- ----------------------------
CREATE INDEX "index_histories_on_action_type" ON "histories" USING btree (
  "action_type" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "index_histories_on_operatable_type_and_action_type" ON "histories" USING btree (
  "operatable_type" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST,
  "action_type" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "index_histories_on_operatable_type_and_action_type_and_store_id" ON "histories" USING btree (
  "operatable_type" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST,
  "action_type" "pg_catalog"."int4_ops" ASC NULLS LAST,
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_histories_on_operatable_type_and_operatable_id" ON "histories" USING btree (
  "operatable_type" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST,
  "operatable_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_histories_on_operator_type_and_operator_id" ON "histories" USING btree (
  "operator_type" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST,
  "operator_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_histories_on_store_id" ON "histories" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table histories
-- ----------------------------
ALTER TABLE "histories" ADD CONSTRAINT "histories_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table homepage_paging_settings
-- ----------------------------
CREATE INDEX "index_homepage_paging_settings_on_custom_page_id" ON "homepage_paging_settings" USING btree (
  "custom_page_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_homepage_paging_settings_on_store_id" ON "homepage_paging_settings" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table homepage_paging_settings
-- ----------------------------
ALTER TABLE "homepage_paging_settings" ADD CONSTRAINT "homepage_paging_settings_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table hot_search_translations
-- ----------------------------
CREATE INDEX "index_hot_search_translations_on_hot_search_id" ON "hot_search_translations" USING btree (
  "hot_search_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_hot_search_translations_on_locale" ON "hot_search_translations" USING btree (
  "locale" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table hot_search_translations
-- ----------------------------
ALTER TABLE "hot_search_translations" ADD CONSTRAINT "hot_search_translations_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table hot_searches
-- ----------------------------
CREATE INDEX "index_hot_searches_on_store_id" ON "hot_searches" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table hot_searches
-- ----------------------------
ALTER TABLE "hot_searches" ADD CONSTRAINT "hot_searches_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table hot_sell_configs
-- ----------------------------
CREATE INDEX "index_hot_sell_configs_on_category_id" ON "hot_sell_configs" USING btree (
  "category_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_hot_sell_configs_on_store_id" ON "hot_sell_configs" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table hot_sell_configs
-- ----------------------------
ALTER TABLE "hot_sell_configs" ADD CONSTRAINT "hot_sell_configs_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table integral_records
-- ----------------------------
CREATE INDEX "index_integral_records_on_member_id" ON "integral_records" USING btree (
  "member_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_integral_records_on_targetable_type_and_targetable_id" ON "integral_records" USING btree (
  "targetable_type" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST,
  "targetable_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table integral_records
-- ----------------------------
ALTER TABLE "integral_records" ADD CONSTRAINT "integral_records_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table invoices
-- ----------------------------
CREATE INDEX "index_invoices_on_user_id" ON "invoices" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table invoices
-- ----------------------------
ALTER TABLE "invoices" ADD CONSTRAINT "invoices_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table item_banner_clicks
-- ----------------------------
CREATE INDEX "index_item_banner_clicks_on_item_banner_id" ON "item_banner_clicks" USING btree (
  "item_banner_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "index_item_banner_clicks_on_item_banner_id_and_date" ON "item_banner_clicks" USING btree (
  "item_banner_id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "date" "pg_catalog"."date_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table item_banner_clicks
-- ----------------------------
ALTER TABLE "item_banner_clicks" ADD CONSTRAINT "item_banner_clicks_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table item_banners
-- ----------------------------
ALTER TABLE "item_banners" ADD CONSTRAINT "item_banners_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table item_nutrition_values
-- ----------------------------
CREATE INDEX "index_item_nutrition_values_on_item_id" ON "item_nutrition_values" USING btree (
  "item_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_item_nutrition_values_on_nutrition_id" ON "item_nutrition_values" USING btree (
  "nutrition_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table item_nutrition_values
-- ----------------------------
ALTER TABLE "item_nutrition_values" ADD CONSTRAINT "item_nutrition_values_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table item_search_histories
-- ----------------------------
CREATE INDEX "index_item_search_histories_on_user_id" ON "item_search_histories" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table item_search_histories
-- ----------------------------
ALTER TABLE "item_search_histories" ADD CONSTRAINT "item_search_histories_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table item_tag_group_translations
-- ----------------------------
CREATE INDEX "index_item_tag_group_translations_on_item_tag_group_id" ON "item_tag_group_translations" USING btree (
  "item_tag_group_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_item_tag_group_translations_on_locale" ON "item_tag_group_translations" USING btree (
  "locale" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table item_tag_group_translations
-- ----------------------------
ALTER TABLE "item_tag_group_translations" ADD CONSTRAINT "item_tag_group_translations_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table item_tag_groups
-- ----------------------------
CREATE INDEX "index_item_tag_groups_on_item_tag_type_id" ON "item_tag_groups" USING btree (
  "item_tag_type_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table item_tag_groups
-- ----------------------------
ALTER TABLE "item_tag_groups" ADD CONSTRAINT "item_tag_groups_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table item_tag_relations
-- ----------------------------
CREATE INDEX "index_item_tag_relations_on_allow_view_same_tag_items" ON "item_tag_relations" USING btree (
  "allow_view_same_tag_items" "pg_catalog"."bool_ops" ASC NULLS LAST
);
CREATE INDEX "index_item_tag_relations_on_item_id" ON "item_tag_relations" USING btree (
  "item_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_item_tag_relations_on_item_tag_id" ON "item_tag_relations" USING btree (
  "item_tag_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table item_tag_relations
-- ----------------------------
ALTER TABLE "item_tag_relations" ADD CONSTRAINT "item_tag_relations_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table item_tag_translations
-- ----------------------------
CREATE INDEX "index_item_tag_translations_on_item_tag_id" ON "item_tag_translations" USING btree (
  "item_tag_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_item_tag_translations_on_locale" ON "item_tag_translations" USING btree (
  "locale" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table item_tag_translations
-- ----------------------------
ALTER TABLE "item_tag_translations" ADD CONSTRAINT "item_tag_translations_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table item_tag_types
-- ----------------------------
ALTER TABLE "item_tag_types" ADD CONSTRAINT "item_tag_types_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table item_tags
-- ----------------------------
CREATE INDEX "index_item_tags_on_item_tag_group_id" ON "item_tags" USING btree (
  "item_tag_group_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table item_tags
-- ----------------------------
ALTER TABLE "item_tags" ADD CONSTRAINT "item_tags_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table item_translations
-- ----------------------------
CREATE INDEX "index_item_translations_on_item_id" ON "item_translations" USING btree (
  "item_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_item_translations_on_locale" ON "item_translations" USING btree (
  "locale" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table item_translations
-- ----------------------------
ALTER TABLE "item_translations" ADD CONSTRAINT "item_translations_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table items
-- ----------------------------
CREATE INDEX "index_items_on_ae_drop_shipper" ON "items" USING btree (
  "ae_drop_shipper" "pg_catalog"."bool_ops" ASC NULLS LAST
);
CREATE INDEX "index_items_on_brand_id" ON "items" USING btree (
  "brand_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_items_on_category_id" ON "items" USING btree (
  "category_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_items_on_hot_sell_config_id" ON "items" USING btree (
  "hot_sell_config_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_items_on_minor_category_id" ON "items" USING btree (
  "minor_category_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "index_items_on_minor_web_category_id" ON "items" USING btree (
  "minor_web_category_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "index_items_on_parent_category_id" ON "items" USING btree (
  "parent_category_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "index_items_on_parent_web_category_id" ON "items" USING btree (
  "parent_web_category_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "index_items_on_product_id" ON "items" USING btree (
  "product_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_items_on_qa_and_guarantee_id" ON "items" USING btree (
  "qa_and_guarantee_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_items_on_quantity" ON "items" USING btree (
  "quantity" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "index_items_on_store_id" ON "items" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_items_on_store_id_and_parent_category_id_and_category_id" ON "items" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "parent_category_id" "pg_catalog"."int4_ops" ASC NULLS LAST,
  "category_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_items_on_web_category_id" ON "items" USING btree (
  "web_category_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table items
-- ----------------------------
ALTER TABLE "items" ADD CONSTRAINT "items_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table kuaidi_company_mappings
-- ----------------------------
CREATE UNIQUE INDEX "index_kuaidi_company_mappings_on_cn_name" ON "kuaidi_company_mappings" USING btree (
  "cn_name" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table kuaidi_company_mappings
-- ----------------------------
ALTER TABLE "kuaidi_company_mappings" ADD CONSTRAINT "kuaidi_company_mappings_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table live_comments
-- ----------------------------
CREATE INDEX "index_live_comments_on_live_room_id" ON "live_comments" USING btree (
  "live_room_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_live_comments_on_user_id" ON "live_comments" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table live_comments
-- ----------------------------
ALTER TABLE "live_comments" ADD CONSTRAINT "live_comments_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table live_room_lotteries
-- ----------------------------
CREATE INDEX "index_live_room_lotteries_on_live_room_id" ON "live_room_lotteries" USING btree (
  "live_room_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table live_room_lotteries
-- ----------------------------
ALTER TABLE "live_room_lotteries" ADD CONSTRAINT "live_room_lotteries_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table live_room_lottery_winning_users
-- ----------------------------
CREATE INDEX "index_live_room_lottery_winning_users_on_live_room_id" ON "live_room_lottery_winning_users" USING btree (
  "live_room_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_live_room_lottery_winning_users_on_live_room_lottery_id" ON "live_room_lottery_winning_users" USING btree (
  "live_room_lottery_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_live_room_lottery_winning_users_on_user_id" ON "live_room_lottery_winning_users" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "index_lottery_winning_users_on_lottery_id_and_user_id" ON "live_room_lottery_winning_users" USING btree (
  "live_room_lottery_id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table live_room_lottery_winning_users
-- ----------------------------
ALTER TABLE "live_room_lottery_winning_users" ADD CONSTRAINT "live_room_lottery_winning_users_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table live_room_orders
-- ----------------------------
CREATE INDEX "index_live_room_orders_on_live_room_id" ON "live_room_orders" USING btree (
  "live_room_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_live_room_orders_on_order_id" ON "live_room_orders" USING btree (
  "order_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_live_room_orders_on_user_id" ON "live_room_orders" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table live_room_orders
-- ----------------------------
ALTER TABLE "live_room_orders" ADD CONSTRAINT "live_room_orders_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table live_room_skus
-- ----------------------------
CREATE INDEX "index_live_room_skus_on_live_room_id" ON "live_room_skus" USING btree (
  "live_room_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_live_room_skus_on_stock_keeping_unit_id" ON "live_room_skus" USING btree (
  "stock_keeping_unit_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table live_room_skus
-- ----------------------------
ALTER TABLE "live_room_skus" ADD CONSTRAINT "live_room_skus_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table live_room_subscriptions
-- ----------------------------
CREATE INDEX "index_live_room_subscriptions_on_live_room_id" ON "live_room_subscriptions" USING btree (
  "live_room_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_live_room_subscriptions_on_user_id" ON "live_room_subscriptions" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table live_room_subscriptions
-- ----------------------------
ALTER TABLE "live_room_subscriptions" ADD CONSTRAINT "live_room_subscriptions_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table live_room_viewed_user_stats
-- ----------------------------
CREATE INDEX "index_live_room_viewed_user_stats_on_live_room_id" ON "live_room_viewed_user_stats" USING btree (
  "live_room_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_live_room_viewed_user_stats_on_time_str" ON "live_room_viewed_user_stats" USING btree (
  "time_str" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table live_room_viewed_user_stats
-- ----------------------------
ALTER TABLE "live_room_viewed_user_stats" ADD CONSTRAINT "live_room_viewed_user_stats_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table live_room_viewed_users
-- ----------------------------
CREATE INDEX "index_live_room_viewed_users_on_live_room_id" ON "live_room_viewed_users" USING btree (
  "live_room_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "index_live_room_viewed_users_on_live_room_id_and_user_id" ON "live_room_viewed_users" USING btree (
  "live_room_id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_live_room_viewed_users_on_user_id" ON "live_room_viewed_users" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table live_room_viewed_users
-- ----------------------------
ALTER TABLE "live_room_viewed_users" ADD CONSTRAINT "live_room_viewed_users_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table live_rooms
-- ----------------------------
CREATE INDEX "index_live_rooms_on_admin_user_id" ON "live_rooms" USING btree (
  "admin_user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_live_rooms_on_coupon_package_id" ON "live_rooms" USING btree (
  "coupon_package_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_live_rooms_on_current_lottery_id" ON "live_rooms" USING btree (
  "current_lottery_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_live_rooms_on_custom_page_id" ON "live_rooms" USING btree (
  "custom_page_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_live_rooms_on_highlighted_sku_id" ON "live_rooms" USING btree (
  "highlighted_sku_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_live_rooms_on_host_id" ON "live_rooms" USING btree (
  "host_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_live_rooms_on_store_id" ON "live_rooms" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table live_rooms
-- ----------------------------
ALTER TABLE "live_rooms" ADD CONSTRAINT "live_rooms_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table logistics
-- ----------------------------
CREATE INDEX "index_logistics_on_no" ON "logistics" USING btree (
  "no" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_logistics_on_order_id" ON "logistics" USING btree (
  "order_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table logistics
-- ----------------------------
ALTER TABLE "logistics" ADD CONSTRAINT "logistics_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table marketing_messages
-- ----------------------------
CREATE INDEX "index_marketing_messages_on_admin_user_id" ON "marketing_messages" USING btree (
  "admin_user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_marketing_messages_on_store_id" ON "marketing_messages" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table marketing_messages
-- ----------------------------
ALTER TABLE "marketing_messages" ADD CONSTRAINT "marketing_messages_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table members
-- ----------------------------
CREATE INDEX "index_members_on_email" ON "members" USING btree (
  "email" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "index_members_on_email_confirmation_token" ON "members" USING btree (
  "email_confirmation_token" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "index_members_on_invite_code" ON "members" USING btree (
  "invite_code" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_members_on_inviter_id" ON "members" USING btree (
  "inviter_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "index_members_on_mobile" ON "members" USING btree (
  "mobile" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_members_on_user_id" ON "members" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Checks structure for table members
-- ----------------------------
ALTER TABLE "members" ADD CONSTRAINT "valid_app_available_integral" CHECK (app_available_integral >= 0);

-- ----------------------------
-- Primary Key structure for table members
-- ----------------------------
ALTER TABLE "members" ADD CONSTRAINT "members_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table message_unread_counters
-- ----------------------------
CREATE INDEX "index_message_unread_counters_on_user_id" ON "message_unread_counters" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table message_unread_counters
-- ----------------------------
ALTER TABLE "message_unread_counters" ADD CONSTRAINT "message_unread_counters_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table mine_page_activity_setting_translations
-- ----------------------------
CREATE INDEX "index_48c11252bac7e9d1a2567836f8d2abe135a5d43e" ON "mine_page_activity_setting_translations" USING btree (
  "mine_page_activity_setting_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_mine_page_activity_setting_translations_on_locale" ON "mine_page_activity_setting_translations" USING btree (
  "locale" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table mine_page_activity_setting_translations
-- ----------------------------
ALTER TABLE "mine_page_activity_setting_translations" ADD CONSTRAINT "mine_page_activity_setting_translations_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table mine_page_activity_settings
-- ----------------------------
CREATE INDEX "index_mine_page_activity_settings_on_custom_page_id" ON "mine_page_activity_settings" USING btree (
  "custom_page_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_mine_page_activity_settings_on_store_id" ON "mine_page_activity_settings" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table mine_page_activity_settings
-- ----------------------------
ALTER TABLE "mine_page_activity_settings" ADD CONSTRAINT "mine_page_activity_settings_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table mobile_blacklists
-- ----------------------------
CREATE UNIQUE INDEX "index_mobile_blacklists_on_mobile" ON "mobile_blacklists" USING btree (
  "mobile" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_mobile_blacklists_on_user_id" ON "mobile_blacklists" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table mobile_blacklists
-- ----------------------------
ALTER TABLE "mobile_blacklists" ADD CONSTRAINT "mobile_blacklists_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table multi_lang_config_translations
-- ----------------------------
CREATE INDEX "index_multi_lang_config_translations_on_locale" ON "multi_lang_config_translations" USING btree (
  "locale" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_multi_lang_config_translations_on_multi_lang_config_id" ON "multi_lang_config_translations" USING btree (
  "multi_lang_config_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table multi_lang_config_translations
-- ----------------------------
ALTER TABLE "multi_lang_config_translations" ADD CONSTRAINT "multi_lang_config_translations_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table multi_lang_configs
-- ----------------------------
CREATE INDEX "index_multi_lang_configs_on_store_id" ON "multi_lang_configs" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table multi_lang_configs
-- ----------------------------
ALTER TABLE "multi_lang_configs" ADD CONSTRAINT "multi_lang_configs_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table nutrition_translations
-- ----------------------------
CREATE INDEX "index_nutrition_translations_on_locale" ON "nutrition_translations" USING btree (
  "locale" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_nutrition_translations_on_nutrition_id" ON "nutrition_translations" USING btree (
  "nutrition_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table nutrition_translations
-- ----------------------------
ALTER TABLE "nutrition_translations" ADD CONSTRAINT "nutrition_translations_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table nutritions
-- ----------------------------
CREATE UNIQUE INDEX "index_nutritions_on_slug" ON "nutritions" USING btree (
  "slug" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table nutritions
-- ----------------------------
ALTER TABLE "nutritions" ADD CONSTRAINT "nutritions_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table operation_records
-- ----------------------------
CREATE INDEX "index_operation_records_on_admin_user_id" ON "operation_records" USING btree (
  "admin_user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_operation_records_on_operatable_type_and_operatable_id" ON "operation_records" USING btree (
  "operatable_type" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST,
  "operatable_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_operation_records_on_store_id" ON "operation_records" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table operation_records
-- ----------------------------
ALTER TABLE "operation_records" ADD CONSTRAINT "operation_records_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table order_date_analyses
-- ----------------------------
CREATE UNIQUE INDEX "index_order_date_analyses_on_delivery_date_and_store_id" ON "order_date_analyses" USING btree (
  "delivery_date" "pg_catalog"."date_ops" ASC NULLS LAST,
  "store_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table order_date_analyses
-- ----------------------------
ALTER TABLE "order_date_analyses" ADD CONSTRAINT "order_date_analyses_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table order_invoices
-- ----------------------------
CREATE UNIQUE INDEX "index_order_invoices_on_no" ON "order_invoices" USING btree (
  "no" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "index_order_invoices_on_order_id" ON "order_invoices" USING btree (
  "order_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table order_invoices
-- ----------------------------
ALTER TABLE "order_invoices" ADD CONSTRAINT "order_invoices_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table order_items
-- ----------------------------
CREATE INDEX "idx_oi_orderid_item" ON "order_items" USING btree (
  "order_id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "item_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "idx_oi_orderid_source" ON "order_items" USING btree (
  "order_id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "source_page_name" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "index_order_items_on_item_id" ON "order_items" USING btree (
  "item_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "index_order_items_on_order_id" ON "order_items" USING btree (
  "order_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_order_items_on_promo_code_id" ON "order_items" USING btree (
  "promo_code_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_order_items_on_source_custom_list_id" ON "order_items" USING btree (
  "source_custom_list_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "index_order_items_on_stock_keeping_unit_id" ON "order_items" USING btree (
  "stock_keeping_unit_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_order_items_on_store_id" ON "order_items" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table order_items
-- ----------------------------
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table orders
-- ----------------------------
CREATE UNIQUE INDEX "index_orders_on_coupon_id" ON "orders" USING btree (
  "coupon_id" "pg_catalog"."int8_ops" ASC NULLS LAST
) WHERE status <> 6;
CREATE INDEX "index_orders_on_created_at" ON "orders" USING btree (
  "created_at" "pg_catalog"."timestamp_ops" ASC NULLS LAST
);
CREATE INDEX "index_orders_on_deleted_by_user_at" ON "orders" USING btree (
  "deleted_by_user_at" "pg_catalog"."timestamp_ops" ASC NULLS LAST
);
CREATE INDEX "index_orders_on_delivery_date" ON "orders" USING btree (
  "delivery_date" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_orders_on_delivery_time_id" ON "orders" USING btree (
  "delivery_time_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "index_orders_on_delivery_time_period_setting_id" ON "orders" USING btree (
  "delivery_time_period_setting_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_orders_on_gift_activity_id" ON "orders" USING btree (
  "gift_activity_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_orders_on_gift_card_coupon_id" ON "orders" USING btree (
  "gift_card_coupon_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_orders_on_gift_coupon_template_id" ON "orders" USING btree (
  "gift_coupon_template_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "index_orders_on_groupon_activity_id" ON "orders" USING btree (
  "groupon_activity_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_orders_on_groupon_id" ON "orders" USING btree (
  "groupon_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_orders_on_next_day_delivery" ON "orders" USING btree (
  "next_day_delivery" "pg_catalog"."bool_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "index_orders_on_no" ON "orders" USING btree (
  "no" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_orders_on_promo_code_id" ON "orders" USING btree (
  "promo_code_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_orders_on_province_id" ON "orders" USING btree (
  "province_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "index_orders_on_refund_no" ON "orders" USING btree (
  "refund_no" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_orders_on_same_day_delivery_time_id" ON "orders" USING btree (
  "same_day_delivery_time_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_orders_on_same_day_delivery_time_period_id" ON "orders" USING btree (
  "same_day_delivery_time_period_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_orders_on_self_pick_up_id" ON "orders" USING btree (
  "self_pick_up_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_orders_on_sku_groupon_id" ON "orders" USING btree (
  "sku_groupon_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_orders_on_store_id" ON "orders" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_orders_on_user_id" ON "orders" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_orders_on_warehouse_order_id" ON "orders" USING btree (
  "warehouse_order_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table orders
-- ----------------------------
ALTER TABLE "orders" ADD CONSTRAINT "orders_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table overseas_student_applications
-- ----------------------------
CREATE INDEX "index_overseas_student_applications_on_user_id" ON "overseas_student_applications" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table overseas_student_applications
-- ----------------------------
ALTER TABLE "overseas_student_applications" ADD CONSTRAINT "overseas_student_applications_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table page_popups
-- ----------------------------
CREATE INDEX "index_page_popups_on_store_id" ON "page_popups" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table page_popups
-- ----------------------------
ALTER TABLE "page_popups" ADD CONSTRAINT "page_popups_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table pages
-- ----------------------------
ALTER TABLE "pages" ADD CONSTRAINT "pages_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table payment_settings
-- ----------------------------
CREATE INDEX "index_payment_settings_on_store_id" ON "payment_settings" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table payment_settings
-- ----------------------------
ALTER TABLE "payment_settings" ADD CONSTRAINT "payment_settings_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table payments
-- ----------------------------
CREATE INDEX "index_payments_on_parent_id" ON "payments" USING btree (
  "parent_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_payments_on_paymentable_type_and_paymentable_id" ON "payments" USING btree (
  "paymentable_type" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST,
  "paymentable_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_payments_on_transaction_id" ON "payments" USING btree (
  "transaction_id" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table payments
-- ----------------------------
ALTER TABLE "payments" ADD CONSTRAINT "payments_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table preferential_pool_translations
-- ----------------------------
CREATE INDEX "index_preferential_pool_translations_on_locale" ON "preferential_pool_translations" USING btree (
  "locale" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_preferential_pool_translations_on_preferential_pool_id" ON "preferential_pool_translations" USING btree (
  "preferential_pool_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table preferential_pool_translations
-- ----------------------------
ALTER TABLE "preferential_pool_translations" ADD CONSTRAINT "preferential_pool_translations_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table preferential_pools
-- ----------------------------
CREATE INDEX "index_preferential_pools_on_store_id" ON "preferential_pools" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table preferential_pools
-- ----------------------------
ALTER TABLE "preferential_pools" ADD CONSTRAINT "preferential_pools_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table products
-- ----------------------------
CREATE INDEX "index_products_on_brand_id" ON "products" USING btree (
  "brand_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_products_on_category_id" ON "products" USING btree (
  "category_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_products_on_minor_category_id" ON "products" USING btree (
  "minor_category_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "index_products_on_qa_and_guarantee_id" ON "products" USING btree (
  "qa_and_guarantee_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_products_on_store_id" ON "products" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table products
-- ----------------------------
ALTER TABLE "products" ADD CONSTRAINT "products_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table promo_code_templates
-- ----------------------------
CREATE INDEX "index_promo_code_templates_on_store_id" ON "promo_code_templates" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table promo_code_templates
-- ----------------------------
ALTER TABLE "promo_code_templates" ADD CONSTRAINT "promo_code_templates_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table promo_codes
-- ----------------------------
CREATE INDEX "index_promo_codes_on_order_id" ON "promo_codes" USING btree (
  "order_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_promo_codes_on_promo_code_template_id" ON "promo_codes" USING btree (
  "promo_code_template_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "index_promo_codes_on_promo_code_template_id_and_code" ON "promo_codes" USING btree (
  "promo_code_template_id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "code" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table promo_codes
-- ----------------------------
ALTER TABLE "promo_codes" ADD CONSTRAINT "promo_codes_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table promo_stock_keeping_units
-- ----------------------------
CREATE INDEX "index_promo_stock_keeping_units_on_promo_code_template_id" ON "promo_stock_keeping_units" USING btree (
  "promo_code_template_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_promo_stock_keeping_units_on_stock_keeping_unit_id" ON "promo_stock_keeping_units" USING btree (
  "stock_keeping_unit_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table promo_stock_keeping_units
-- ----------------------------
ALTER TABLE "promo_stock_keeping_units" ADD CONSTRAINT "promo_stock_keeping_units_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table provinces
-- ----------------------------
ALTER TABLE "provinces" ADD CONSTRAINT "provinces_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table push_message_read_logs
-- ----------------------------
CREATE INDEX "index_push_message_read_logs_on_push_message_id" ON "push_message_read_logs" USING btree (
  "push_message_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_push_message_read_logs_on_user_id" ON "push_message_read_logs" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "index_push_message_read_logs_on_user_id_and_push_message_id" ON "push_message_read_logs" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "push_message_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table push_message_read_logs
-- ----------------------------
ALTER TABLE "push_message_read_logs" ADD CONSTRAINT "push_message_read_logs_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table push_messages
-- ----------------------------
CREATE INDEX "index_push_messages_on_admin_user_id" ON "push_messages" USING btree (
  "admin_user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_push_messages_on_path_customized_attrs" ON "push_messages" USING btree (
  "path_customized_id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "path_customized_type" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_push_messages_on_store_id" ON "push_messages" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table push_messages
-- ----------------------------
ALTER TABLE "push_messages" ADD CONSTRAINT "push_messages_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table qa_and_guarantee_translations
-- ----------------------------
CREATE INDEX "index_qa_and_guarantee_translations_on_locale" ON "qa_and_guarantee_translations" USING btree (
  "locale" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_qa_and_guarantee_translations_on_qa_and_guarantee_id" ON "qa_and_guarantee_translations" USING btree (
  "qa_and_guarantee_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table qa_and_guarantee_translations
-- ----------------------------
ALTER TABLE "qa_and_guarantee_translations" ADD CONSTRAINT "qa_and_guarantee_translations_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table qa_and_guarantees
-- ----------------------------
ALTER TABLE "qa_and_guarantees" ADD CONSTRAINT "qa_and_guarantees_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table random_reduction_coupon_template_rules
-- ----------------------------
CREATE INDEX "index_random_reduction_rules_on_coupon_template_id" ON "random_reduction_coupon_template_rules" USING btree (
  "coupon_template_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table random_reduction_coupon_template_rules
-- ----------------------------
ALTER TABLE "random_reduction_coupon_template_rules" ADD CONSTRAINT "random_reduction_coupon_template_rules_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table report_pages
-- ----------------------------
CREATE INDEX "index_report_pages_on_creator_id" ON "report_pages" USING btree (
  "creator_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table report_pages
-- ----------------------------
ALTER TABLE "report_pages" ADD CONSTRAINT "report_pages_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table role_templates
-- ----------------------------
ALTER TABLE "role_templates" ADD CONSTRAINT "role_templates_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table same_day_delivery_cart_items
-- ----------------------------
CREATE INDEX "index_same_day_cart_items_on_shopping_cart_id" ON "same_day_delivery_cart_items" USING btree (
  "same_day_delivery_cart_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "index_same_day_cart_items_on_shopping_cart_id_and_sku_id" ON "same_day_delivery_cart_items" USING btree (
  "same_day_delivery_cart_id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "stock_keeping_unit_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_same_day_cart_items_on_source_custom_list_id" ON "same_day_delivery_cart_items" USING btree (
  "source_custom_list_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "index_same_day_cart_items_on_stock_keeping_unit_id" ON "same_day_delivery_cart_items" USING btree (
  "stock_keeping_unit_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_same_day_delivery_cart_items_on_store_id" ON "same_day_delivery_cart_items" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table same_day_delivery_cart_items
-- ----------------------------
ALTER TABLE "same_day_delivery_cart_items" ADD CONSTRAINT "same_day_delivery_cart_items_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table same_day_delivery_carts
-- ----------------------------
CREATE INDEX "index_same_day_delivery_carts_on_user_id" ON "same_day_delivery_carts" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table same_day_delivery_carts
-- ----------------------------
ALTER TABLE "same_day_delivery_carts" ADD CONSTRAINT "same_day_delivery_carts_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table same_day_delivery_time_periods
-- ----------------------------
CREATE INDEX "index_delivery_time_periods_on_same_day_delivery_time_id" ON "same_day_delivery_time_periods" USING btree (
  "same_day_delivery_time_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table same_day_delivery_time_periods
-- ----------------------------
ALTER TABLE "same_day_delivery_time_periods" ADD CONSTRAINT "same_day_delivery_time_periods_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table same_day_delivery_times
-- ----------------------------
ALTER TABLE "same_day_delivery_times" ADD CONSTRAINT "same_day_delivery_times_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table schema_migrations
-- ----------------------------
ALTER TABLE "schema_migrations" ADD CONSTRAINT "schema_migrations_pkey" PRIMARY KEY ("version");

-- ----------------------------
-- Indexes structure for table self_pick_order_date_analyses
-- ----------------------------
CREATE UNIQUE INDEX "self_pick_order_on_delivery_date_and_self_pick_up" ON "self_pick_order_date_analyses" USING btree (
  "delivery_date" "pg_catalog"."date_ops" ASC NULLS LAST,
  "self_pick_up_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table self_pick_order_date_analyses
-- ----------------------------
ALTER TABLE "self_pick_order_date_analyses" ADD CONSTRAINT "self_pick_order_date_analyses_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table self_pick_ups
-- ----------------------------
CREATE INDEX "index_self_pick_ups_on_store_id" ON "self_pick_ups" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table self_pick_ups
-- ----------------------------
ALTER TABLE "self_pick_ups" ADD CONSTRAINT "self_pick_ups_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table share_settings
-- ----------------------------
CREATE INDEX "index_share_settings_on_store_id" ON "share_settings" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_share_settings_on_target_type_and_target_id" ON "share_settings" USING btree (
  "target_type" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST,
  "target_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table share_settings
-- ----------------------------
ALTER TABLE "share_settings" ADD CONSTRAINT "share_settings_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table shopline_users
-- ----------------------------
ALTER TABLE "shopline_users" ADD CONSTRAINT "shopline_users_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table shopping_cart_items
-- ----------------------------
CREATE UNIQUE INDEX "index_cart_items_on_shopping_cart_id_and_sku_id" ON "shopping_cart_items" USING btree (
  "shopping_cart_id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "stock_keeping_unit_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_shopping_cart_items_on_shopping_cart_id" ON "shopping_cart_items" USING btree (
  "shopping_cart_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_shopping_cart_items_on_source_custom_list_id" ON "shopping_cart_items" USING btree (
  "source_custom_list_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "index_shopping_cart_items_on_stock_keeping_unit_id" ON "shopping_cart_items" USING btree (
  "stock_keeping_unit_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_shopping_cart_items_on_store_id" ON "shopping_cart_items" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table shopping_cart_items
-- ----------------------------
ALTER TABLE "shopping_cart_items" ADD CONSTRAINT "shopping_cart_items_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table shopping_carts
-- ----------------------------
CREATE INDEX "index_shopping_carts_on_user_id" ON "shopping_carts" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table shopping_carts
-- ----------------------------
ALTER TABLE "shopping_carts" ADD CONSTRAINT "shopping_carts_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table shortened_scenes
-- ----------------------------
CREATE INDEX "index_shortened_scenes_on_short_scene" ON "shortened_scenes" USING btree (
  "short_scene" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table shortened_scenes
-- ----------------------------
ALTER TABLE "shortened_scenes" ADD CONSTRAINT "shortened_scenes_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table sign_in_activities
-- ----------------------------
ALTER TABLE "sign_in_activities" ADD CONSTRAINT "sign_in_activities_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table sign_in_activity_translations
-- ----------------------------
CREATE INDEX "index_sign_in_activity_translations_on_locale" ON "sign_in_activity_translations" USING btree (
  "locale" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_sign_in_activity_translations_on_sign_in_activity_id" ON "sign_in_activity_translations" USING btree (
  "sign_in_activity_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table sign_in_activity_translations
-- ----------------------------
ALTER TABLE "sign_in_activity_translations" ADD CONSTRAINT "sign_in_activity_translations_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table sign_in_histories
-- ----------------------------
CREATE INDEX "index_sign_in_histories_on_sign_in_activity_id" ON "sign_in_histories" USING btree (
  "sign_in_activity_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "index_sign_in_histories_on_user_and_activity_and_sign_in_date" ON "sign_in_histories" USING btree (
  "sign_in_activity_id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "sign_in_date" "pg_catalog"."date_ops" ASC NULLS LAST
);
CREATE INDEX "index_sign_in_histories_on_user_id" ON "sign_in_histories" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table sign_in_histories
-- ----------------------------
ALTER TABLE "sign_in_histories" ADD CONSTRAINT "sign_in_histories_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table sign_in_reward_histories
-- ----------------------------
CREATE INDEX "index_sign_in_reward_histories_on_sign_in_activity_id" ON "sign_in_reward_histories" USING btree (
  "sign_in_activity_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_sign_in_reward_histories_on_sign_in_history_id" ON "sign_in_reward_histories" USING btree (
  "sign_in_history_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_sign_in_reward_histories_on_user_id" ON "sign_in_reward_histories" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table sign_in_reward_histories
-- ----------------------------
ALTER TABLE "sign_in_reward_histories" ADD CONSTRAINT "sign_in_reward_histories_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table site_configs
-- ----------------------------
CREATE INDEX "index_site_configs_on_store_id" ON "site_configs" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table site_configs
-- ----------------------------
ALTER TABLE "site_configs" ADD CONSTRAINT "site_configs_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table sku_groupons
-- ----------------------------
CREATE UNIQUE INDEX "index_sku_groupons_on_groupon_activity_and_stock_keeping_unit" ON "sku_groupons" USING btree (
  "groupon_activity_id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "stock_keeping_unit_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_sku_groupons_on_groupon_activity_id" ON "sku_groupons" USING btree (
  "groupon_activity_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_sku_groupons_on_item_id" ON "sku_groupons" USING btree (
  "item_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_sku_groupons_on_stock_keeping_unit_id" ON "sku_groupons" USING btree (
  "stock_keeping_unit_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table sku_groupons
-- ----------------------------
ALTER TABLE "sku_groupons" ADD CONSTRAINT "sku_groupons_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table sku_in_stock_notices
-- ----------------------------
CREATE INDEX "index_sku_in_stock_notices_on_stock_keeping_unit_id" ON "sku_in_stock_notices" USING btree (
  "stock_keeping_unit_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_sku_in_stock_notices_on_user_id" ON "sku_in_stock_notices" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table sku_in_stock_notices
-- ----------------------------
ALTER TABLE "sku_in_stock_notices" ADD CONSTRAINT "sku_in_stock_notices_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table sku_inventory_snapshots
-- ----------------------------
CREATE INDEX "index_sku_inventory_snapshots_on_stock_keeping_unit_id" ON "sku_inventory_snapshots" USING btree (
  "stock_keeping_unit_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "sku_inventory_snapshots_on_sku_id_and_record_date" ON "sku_inventory_snapshots" USING btree (
  "stock_keeping_unit_id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "record_date" "pg_catalog"."date_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table sku_inventory_snapshots
-- ----------------------------
ALTER TABLE "sku_inventory_snapshots" ADD CONSTRAINT "sku_inventory_snapshots_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table sku_properties
-- ----------------------------
CREATE INDEX "index_sku_properties_on_ae_property_id" ON "sku_properties" USING btree (
  "ae_property_id" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table sku_properties
-- ----------------------------
ALTER TABLE "sku_properties" ADD CONSTRAINT "sku_properties_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table sku_property_translations
-- ----------------------------
CREATE INDEX "index_sku_property_translations_on_locale" ON "sku_property_translations" USING btree (
  "locale" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_sku_property_translations_on_sku_property_id" ON "sku_property_translations" USING btree (
  "sku_property_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table sku_property_translations
-- ----------------------------
ALTER TABLE "sku_property_translations" ADD CONSTRAINT "sku_property_translations_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table sku_sales_mailer_settings
-- ----------------------------
CREATE INDEX "index_sku_sales_mailer_settings_on_store_id" ON "sku_sales_mailer_settings" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table sku_sales_mailer_settings
-- ----------------------------
ALTER TABLE "sku_sales_mailer_settings" ADD CONSTRAINT "sku_sales_mailer_settings_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table sku_valid_inventory_dates
-- ----------------------------
CREATE INDEX "index_sku_valid_inventory_dates_on_stock_keeping_unit_id" ON "sku_valid_inventory_dates" USING btree (
  "stock_keeping_unit_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_sku_valid_inventory_dates_on_store_id" ON "sku_valid_inventory_dates" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table sku_valid_inventory_dates
-- ----------------------------
ALTER TABLE "sku_valid_inventory_dates" ADD CONSTRAINT "sku_valid_inventory_dates_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table sku_value_translations
-- ----------------------------
CREATE INDEX "index_sku_value_translations_on_locale" ON "sku_value_translations" USING btree (
  "locale" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_sku_value_translations_on_sku_value_id" ON "sku_value_translations" USING btree (
  "sku_value_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table sku_value_translations
-- ----------------------------
ALTER TABLE "sku_value_translations" ADD CONSTRAINT "sku_value_translations_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table sku_values
-- ----------------------------
CREATE INDEX "index_sku_values_on_sku_property_id" ON "sku_values" USING btree (
  "sku_property_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_sku_values_on_sku_property_id_and_ae_property_value_id" ON "sku_values" USING btree (
  "sku_property_id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "ae_property_value_id" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table sku_values
-- ----------------------------
ALTER TABLE "sku_values" ADD CONSTRAINT "sku_values_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table stock_keeping_units
-- ----------------------------
CREATE UNIQUE INDEX "index_stock_keeping_units_on_barcode_and_store_id" ON "stock_keeping_units" USING btree (
  "barcode" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST,
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_stock_keeping_units_on_created_at" ON "stock_keeping_units" USING btree (
  "created_at" "pg_catalog"."timestamp_ops" ASC NULLS LAST
);
CREATE INDEX "index_stock_keeping_units_on_id_and_item_id" ON "stock_keeping_units" USING btree (
  "id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "item_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_stock_keeping_units_on_item_id" ON "stock_keeping_units" USING btree (
  "item_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "index_stock_keeping_units_on_item_id_and_properties" ON "stock_keeping_units" USING btree (
  "item_id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "properties" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "index_stock_keeping_units_on_no_and_store_id" ON "stock_keeping_units" USING btree (
  "no" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST,
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_stock_keeping_units_on_store_id" ON "stock_keeping_units" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Checks structure for table stock_keeping_units
-- ----------------------------
ALTER TABLE "stock_keeping_units" ADD CONSTRAINT "valid_quantity" CHECK (quantity >= 0);

-- ----------------------------
-- Primary Key structure for table stock_keeping_units
-- ----------------------------
ALTER TABLE "stock_keeping_units" ADD CONSTRAINT "stock_keeping_units_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table stores
-- ----------------------------
CREATE INDEX "index_stores_on_default_au_suburb_id" ON "stores" USING btree (
  "default_au_suburb_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "index_stores_on_short_name" ON "stores" USING btree (
  "short_name" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table stores
-- ----------------------------
ALTER TABLE "stores" ADD CONSTRAINT "stores_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table subscribe_records
-- ----------------------------
CREATE INDEX "index_subscribe_records_on_targetable_type_and_targetable_id" ON "subscribe_records" USING btree (
  "targetable_type" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST,
  "targetable_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_subscribe_records_on_user_id" ON "subscribe_records" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table subscribe_records
-- ----------------------------
ALTER TABLE "subscribe_records" ADD CONSTRAINT "subscribe_records_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table suppliers
-- ----------------------------
CREATE INDEX "index_suppliers_on_stock_keeping_unit_id" ON "suppliers" USING btree (
  "stock_keeping_unit_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table suppliers
-- ----------------------------
ALTER TABLE "suppliers" ADD CONSTRAINT "suppliers_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table taggings
-- ----------------------------
CREATE INDEX "index_taggings_on_context" ON "taggings" USING btree (
  "context" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_taggings_on_tag_id" ON "taggings" USING btree (
  "tag_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "index_taggings_on_taggable_id" ON "taggings" USING btree (
  "taggable_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "index_taggings_on_taggable_id_and_taggable_type_and_context" ON "taggings" USING btree (
  "taggable_id" "pg_catalog"."int4_ops" ASC NULLS LAST,
  "taggable_type" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST,
  "context" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_taggings_on_taggable_type" ON "taggings" USING btree (
  "taggable_type" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_taggings_on_tagger_id" ON "taggings" USING btree (
  "tagger_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "index_taggings_on_tagger_id_and_tagger_type" ON "taggings" USING btree (
  "tagger_id" "pg_catalog"."int4_ops" ASC NULLS LAST,
  "tagger_type" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "taggings_idx" ON "taggings" USING btree (
  "tag_id" "pg_catalog"."int4_ops" ASC NULLS LAST,
  "taggable_id" "pg_catalog"."int4_ops" ASC NULLS LAST,
  "taggable_type" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST,
  "context" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST,
  "tagger_id" "pg_catalog"."int4_ops" ASC NULLS LAST,
  "tagger_type" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "taggings_idy" ON "taggings" USING btree (
  "taggable_id" "pg_catalog"."int4_ops" ASC NULLS LAST,
  "taggable_type" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST,
  "tagger_id" "pg_catalog"."int4_ops" ASC NULLS LAST,
  "context" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table taggings
-- ----------------------------
ALTER TABLE "taggings" ADD CONSTRAINT "taggings_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table tags
-- ----------------------------
CREATE UNIQUE INDEX "index_tags_on_name" ON "tags" USING btree (
  "name" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table tags
-- ----------------------------
ALTER TABLE "tags" ADD CONSTRAINT "tags_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table third_party_categories
-- ----------------------------
CREATE INDEX "index_third_party_categories_on_category_id" ON "third_party_categories" USING btree (
  "category_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_third_party_categories_on_third_party_id" ON "third_party_categories" USING btree (
  "third_party_id" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table third_party_categories
-- ----------------------------
ALTER TABLE "third_party_categories" ADD CONSTRAINT "third_party_categories_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table third_party_items
-- ----------------------------
CREATE INDEX "index_third_party_items_on_item_id" ON "third_party_items" USING btree (
  "item_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "index_third_party_items_on_item_id_and_third_party_type" ON "third_party_items" USING btree (
  "item_id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "third_party_type" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "index_third_party_items_on_third_party_id" ON "third_party_items" USING btree (
  "third_party_id" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table third_party_items
-- ----------------------------
ALTER TABLE "third_party_items" ADD CONSTRAINT "third_party_items_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table third_party_orders
-- ----------------------------
CREATE INDEX "index_third_party_orders_on_store_id" ON "third_party_orders" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_third_party_orders_on_warehouse_order_id" ON "third_party_orders" USING btree (
  "warehouse_order_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table third_party_orders
-- ----------------------------
ALTER TABLE "third_party_orders" ADD CONSTRAINT "third_party_orders_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table third_party_skus
-- ----------------------------
CREATE UNIQUE INDEX "index_third_party_skus_on_sku_id_and_type" ON "third_party_skus" USING btree (
  "stock_keeping_unit_id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "third_party_type" "pg_catalog"."int4_ops" ASC NULLS LAST
);
CREATE INDEX "index_third_party_skus_on_stock_keeping_unit_id" ON "third_party_skus" USING btree (
  "stock_keeping_unit_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_third_party_skus_on_third_party_id" ON "third_party_skus" USING btree (
  "third_party_id" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table third_party_skus
-- ----------------------------
ALTER TABLE "third_party_skus" ADD CONSTRAINT "third_party_skus_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table third_party_users
-- ----------------------------
CREATE INDEX "index_third_party_users_on_store_id" ON "third_party_users" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table third_party_users
-- ----------------------------
ALTER TABLE "third_party_users" ADD CONSTRAINT "third_party_users_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table time_limited_promotion_prices
-- ----------------------------
CREATE INDEX "index_time_limited_promotion_prices_on_sku_id" ON "time_limited_promotion_prices" USING btree (
  "stock_keeping_unit_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_time_limited_promotion_prices_on_store_id" ON "time_limited_promotion_prices" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_time_limited_promotion_prices_on_store_id_and_enabled" ON "time_limited_promotion_prices" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST,
  "enabled" "pg_catalog"."bool_ops" ASC NULLS LAST
);
CREATE INDEX "index_time_limited_promotion_prices_on_tlp_id" ON "time_limited_promotion_prices" USING btree (
  "time_limited_promotion_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table time_limited_promotion_prices
-- ----------------------------
ALTER TABLE "time_limited_promotion_prices" ADD CONSTRAINT "time_limited_promotion_prices_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table time_limited_promotions
-- ----------------------------
CREATE INDEX "index_time_limited_promotions_on_store_id" ON "time_limited_promotions" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table time_limited_promotions
-- ----------------------------
ALTER TABLE "time_limited_promotions" ADD CONSTRAINT "time_limited_promotions_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table top_left_item_tags
-- ----------------------------
CREATE INDEX "index_top_left_item_tags_on_store_id" ON "top_left_item_tags" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table top_left_item_tags
-- ----------------------------
ALTER TABLE "top_left_item_tags" ADD CONSTRAINT "top_left_item_tags_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table user_histories
-- ----------------------------
CREATE INDEX "index_user_histories_on_operatable_type_and_operatable_id" ON "user_histories" USING btree (
  "operatable_type" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST,
  "operatable_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_user_histories_on_user_id" ON "user_histories" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table user_histories
-- ----------------------------
ALTER TABLE "user_histories" ADD CONSTRAINT "user_histories_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table user_recommended_products
-- ----------------------------
CREATE INDEX "index_user_recommended_products_on_user_id" ON "user_recommended_products" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table user_recommended_products
-- ----------------------------
ALTER TABLE "user_recommended_products" ADD CONSTRAINT "user_recommended_products_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table user_suggestions
-- ----------------------------
CREATE INDEX "index_user_suggestions_on_user_id" ON "user_suggestions" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table user_suggestions
-- ----------------------------
ALTER TABLE "user_suggestions" ADD CONSTRAINT "user_suggestions_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table users
-- ----------------------------
CREATE UNIQUE INDEX "index_users_on_aus_mp_open_id" ON "users" USING btree (
  "aus_mp_open_id" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "index_users_on_ebest_platform_unionid" ON "users" USING btree (
  "ebest_platform_unionid" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_users_on_selected_store_id" ON "users" USING btree (
  "selected_store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "index_users_on_unionid" ON "users" USING btree (
  "unionid" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table users
-- ----------------------------
ALTER TABLE "users" ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table users_push_messages
-- ----------------------------
CREATE INDEX "index_users_push_messages_on_push_message_id" ON "users_push_messages" USING btree (
  "push_message_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_users_push_messages_on_user_id" ON "users_push_messages" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table users_push_messages
-- ----------------------------
ALTER TABLE "users_push_messages" ADD CONSTRAINT "users_push_messages_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table warehouse_orders
-- ----------------------------
CREATE INDEX "index_warehouse_orders_on_store_id" ON "warehouse_orders" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_warehouse_orders_on_user_id" ON "warehouse_orders" USING btree (
  "user_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table warehouse_orders
-- ----------------------------
ALTER TABLE "warehouse_orders" ADD CONSTRAINT "warehouse_orders_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table web_banner_items
-- ----------------------------
CREATE INDEX "index_web_banner_items_on_web_banner_id" ON "web_banner_items" USING btree (
  "web_banner_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table web_banner_items
-- ----------------------------
ALTER TABLE "web_banner_items" ADD CONSTRAINT "web_banner_items_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table web_banners
-- ----------------------------
CREATE INDEX "index_web_banners_on_store_id" ON "web_banners" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table web_banners
-- ----------------------------
ALTER TABLE "web_banners" ADD CONSTRAINT "web_banners_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table web_categories
-- ----------------------------
CREATE INDEX "index_web_categories_on_parent_id" ON "web_categories" USING btree (
  "parent_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table web_categories
-- ----------------------------
ALTER TABLE "web_categories" ADD CONSTRAINT "web_categories_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table web_category_translations
-- ----------------------------
CREATE INDEX "index_web_category_translations_on_locale" ON "web_category_translations" USING btree (
  "locale" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_web_category_translations_on_web_category_id" ON "web_category_translations" USING btree (
  "web_category_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table web_category_translations
-- ----------------------------
ALTER TABLE "web_category_translations" ADD CONSTRAINT "web_category_translations_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table web_custom_list_items
-- ----------------------------
CREATE INDEX "index_web_custom_list_items_on_item_id" ON "web_custom_list_items" USING btree (
  "item_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_web_custom_list_items_on_web_custom_list_id" ON "web_custom_list_items" USING btree (
  "web_custom_list_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table web_custom_list_items
-- ----------------------------
ALTER TABLE "web_custom_list_items" ADD CONSTRAINT "web_custom_list_items_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table web_custom_list_translations
-- ----------------------------
CREATE INDEX "index_web_custom_list_translations_on_locale" ON "web_custom_list_translations" USING btree (
  "locale" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_web_custom_list_translations_on_web_custom_list_id" ON "web_custom_list_translations" USING btree (
  "web_custom_list_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table web_custom_list_translations
-- ----------------------------
ALTER TABLE "web_custom_list_translations" ADD CONSTRAINT "web_custom_list_translations_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table web_custom_lists
-- ----------------------------
CREATE INDEX "index_web_custom_lists_on_store_id" ON "web_custom_lists" USING btree (
  "store_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table web_custom_lists
-- ----------------------------
ALTER TABLE "web_custom_lists" ADD CONSTRAINT "web_custom_lists_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Indexes structure for table web_items
-- ----------------------------
CREATE INDEX "index_web_items_on_item_id" ON "web_items" USING btree (
  "item_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table web_items
-- ----------------------------
ALTER TABLE "web_items" ADD CONSTRAINT "web_items_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Primary Key structure for table wms_inventories
-- ----------------------------
ALTER TABLE "wms_inventories" ADD CONSTRAINT "wms_inventories_pkey" PRIMARY KEY ("id");

-- ----------------------------
-- Foreign Keys structure for table admin_users
-- ----------------------------
ALTER TABLE "admin_users" ADD CONSTRAINT "fk_rails_0ab537babc" FOREIGN KEY ("creator_id") REFERENCES "admin_users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table after_sales_order_items
-- ----------------------------
ALTER TABLE "after_sales_order_items" ADD CONSTRAINT "fk_rails_6bed0c2f6c" FOREIGN KEY ("after_sale_id") REFERENCES "after_sales" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "after_sales_order_items" ADD CONSTRAINT "fk_rails_6f509fc8b3" FOREIGN KEY ("order_item_id") REFERENCES "order_items" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table age_verifications
-- ----------------------------
ALTER TABLE "age_verifications" ADD CONSTRAINT "fk_rails_86b2367653" FOREIGN KEY ("parent_web_category_id") REFERENCES "web_categories" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "age_verifications" ADD CONSTRAINT "fk_rails_ea0d94c988" FOREIGN KEY ("parent_category_id") REFERENCES "categories" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table app_text_messages
-- ----------------------------
ALTER TABLE "app_text_messages" ADD CONSTRAINT "fk_rails_8d68d83e49" FOREIGN KEY ("admin_user_id") REFERENCES "admin_users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "app_text_messages" ADD CONSTRAINT "fk_rails_ad52fe11e6" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table auction_activities
-- ----------------------------
ALTER TABLE "auction_activities" ADD CONSTRAINT "fk_rails_0a8b868b4f" FOREIGN KEY ("brand_id") REFERENCES "brands" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "auction_activities" ADD CONSTRAINT "fk_rails_0baf943076" FOREIGN KEY ("order_id") REFERENCES "orders" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "auction_activities" ADD CONSTRAINT "fk_rails_14d6376163" FOREIGN KEY ("best_automatic_bid_id") REFERENCES "auction_automatic_bids" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "auction_activities" ADD CONSTRAINT "fk_rails_30c7a1ef3e" FOREIGN KEY ("item_id") REFERENCES "items" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "auction_activities" ADD CONSTRAINT "fk_rails_7684eb7984" FOREIGN KEY ("qa_and_guarantee_id") REFERENCES "qa_and_guarantees" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "auction_activities" ADD CONSTRAINT "fk_rails_ce10ffe4da" FOREIGN KEY ("stock_keeping_unit_id") REFERENCES "stock_keeping_units" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "auction_activities" ADD CONSTRAINT "fk_rails_d66b070abc" FOREIGN KEY ("best_bid_id") REFERENCES "auction_bids" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "auction_activities" ADD CONSTRAINT "fk_rails_d96921567a" FOREIGN KEY ("store_id") REFERENCES "stores" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table auction_activity_participations
-- ----------------------------
ALTER TABLE "auction_activity_participations" ADD CONSTRAINT "fk_rails_1e4e610ee2" FOREIGN KEY ("auction_order_id") REFERENCES "orders" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "auction_activity_participations" ADD CONSTRAINT "fk_rails_b1b7dc4790" FOREIGN KEY ("auction_activity_id") REFERENCES "auction_activities" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "auction_activity_participations" ADD CONSTRAINT "fk_rails_b390fab239" FOREIGN KEY ("store_id") REFERENCES "stores" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "auction_activity_participations" ADD CONSTRAINT "fk_rails_f19a7d9c12" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table auction_automatic_bids
-- ----------------------------
ALTER TABLE "auction_automatic_bids" ADD CONSTRAINT "fk_rails_08c6b3fc04" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "auction_automatic_bids" ADD CONSTRAINT "fk_rails_34c3044c27" FOREIGN KEY ("auction_activity_id") REFERENCES "auction_activities" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table auction_bids
-- ----------------------------
ALTER TABLE "auction_bids" ADD CONSTRAINT "fk_rails_63aed155e9" FOREIGN KEY ("member_id") REFERENCES "members" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "auction_bids" ADD CONSTRAINT "fk_rails_a8cc37bb2c" FOREIGN KEY ("auction_activity_id") REFERENCES "auction_activities" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "auction_bids" ADD CONSTRAINT "fk_rails_c1245bf588" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table cities
-- ----------------------------
ALTER TABLE "cities" ADD CONSTRAINT "fk_rails_ea36d40e0b" FOREIGN KEY ("province_id") REFERENCES "provinces" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table counties
-- ----------------------------
ALTER TABLE "counties" ADD CONSTRAINT "fk_rails_780cb2dd53" FOREIGN KEY ("city_id") REFERENCES "cities" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table custom_pages
-- ----------------------------
ALTER TABLE "custom_pages" ADD CONSTRAINT "fk_rails_4dc63dada7" FOREIGN KEY ("creator_id") REFERENCES "admin_users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table event_form_records
-- ----------------------------
ALTER TABLE "event_form_records" ADD CONSTRAINT "fk_rails_48e3379517" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table hot_searches
-- ----------------------------
ALTER TABLE "hot_searches" ADD CONSTRAINT "fk_rails_b1c295e4ee" FOREIGN KEY ("store_id") REFERENCES "stores" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table integral_records
-- ----------------------------
ALTER TABLE "integral_records" ADD CONSTRAINT "fk_rails_2628610bf4" FOREIGN KEY ("member_id") REFERENCES "members" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table invoices
-- ----------------------------
ALTER TABLE "invoices" ADD CONSTRAINT "fk_rails_3d1522a0d8" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table item_nutrition_values
-- ----------------------------
ALTER TABLE "item_nutrition_values" ADD CONSTRAINT "fk_rails_251cd003ad" FOREIGN KEY ("nutrition_id") REFERENCES "nutritions" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "item_nutrition_values" ADD CONSTRAINT "fk_rails_2f7287d2e0" FOREIGN KEY ("item_id") REFERENCES "items" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table items
-- ----------------------------
ALTER TABLE "items" ADD CONSTRAINT "fk_rails_e1c286bb05" FOREIGN KEY ("qa_and_guarantee_id") REFERENCES "qa_and_guarantees" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table live_room_lotteries
-- ----------------------------
ALTER TABLE "live_room_lotteries" ADD CONSTRAINT "fk_rails_9af8819e00" FOREIGN KEY ("live_room_id") REFERENCES "live_rooms" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table live_room_lottery_winning_users
-- ----------------------------
ALTER TABLE "live_room_lottery_winning_users" ADD CONSTRAINT "fk_rails_1cb7c3a710" FOREIGN KEY ("live_room_lottery_id") REFERENCES "live_room_lotteries" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "live_room_lottery_winning_users" ADD CONSTRAINT "fk_rails_43fc7f2a70" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "live_room_lottery_winning_users" ADD CONSTRAINT "fk_rails_69ede379ab" FOREIGN KEY ("live_room_id") REFERENCES "live_rooms" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table live_room_orders
-- ----------------------------
ALTER TABLE "live_room_orders" ADD CONSTRAINT "fk_rails_05d688409a" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "live_room_orders" ADD CONSTRAINT "fk_rails_3a8777fa21" FOREIGN KEY ("live_room_id") REFERENCES "live_rooms" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "live_room_orders" ADD CONSTRAINT "fk_rails_e4b95b3a57" FOREIGN KEY ("order_id") REFERENCES "orders" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table live_room_subscriptions
-- ----------------------------
ALTER TABLE "live_room_subscriptions" ADD CONSTRAINT "fk_rails_450e32efcf" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "live_room_subscriptions" ADD CONSTRAINT "fk_rails_7b3d04df01" FOREIGN KEY ("live_room_id") REFERENCES "live_rooms" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table live_room_viewed_user_stats
-- ----------------------------
ALTER TABLE "live_room_viewed_user_stats" ADD CONSTRAINT "fk_rails_8959594a95" FOREIGN KEY ("live_room_id") REFERENCES "live_rooms" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table live_room_viewed_users
-- ----------------------------
ALTER TABLE "live_room_viewed_users" ADD CONSTRAINT "fk_rails_afd60883f7" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "live_room_viewed_users" ADD CONSTRAINT "fk_rails_e13ee104c4" FOREIGN KEY ("live_room_id") REFERENCES "live_rooms" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table live_rooms
-- ----------------------------
ALTER TABLE "live_rooms" ADD CONSTRAINT "fk_rails_03c9d23fd0" FOREIGN KEY ("highlighted_sku_id") REFERENCES "stock_keeping_units" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "live_rooms" ADD CONSTRAINT "fk_rails_44ef712e5c" FOREIGN KEY ("coupon_package_id") REFERENCES "coupon_packages" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "live_rooms" ADD CONSTRAINT "fk_rails_8aae70ca6a" FOREIGN KEY ("current_lottery_id") REFERENCES "live_room_lotteries" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table members
-- ----------------------------
ALTER TABLE "members" ADD CONSTRAINT "fk_rails_2e88fb7ce9" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table message_unread_counters
-- ----------------------------
ALTER TABLE "message_unread_counters" ADD CONSTRAINT "fk_rails_2a3440ddde" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table mobile_blacklists
-- ----------------------------
ALTER TABLE "mobile_blacklists" ADD CONSTRAINT "fk_rails_653744d07e" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table multi_lang_configs
-- ----------------------------
ALTER TABLE "multi_lang_configs" ADD CONSTRAINT "fk_rails_4581acca32" FOREIGN KEY ("store_id") REFERENCES "stores" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table order_invoices
-- ----------------------------
ALTER TABLE "order_invoices" ADD CONSTRAINT "fk_rails_ba9ad21acc" FOREIGN KEY ("order_id") REFERENCES "orders" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table orders
-- ----------------------------
ALTER TABLE "orders" ADD CONSTRAINT "fk_rails_0ea622aac8" FOREIGN KEY ("self_pick_up_id") REFERENCES "self_pick_ups" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "orders" ADD CONSTRAINT "fk_rails_4b88ad4567" FOREIGN KEY ("groupon_id") REFERENCES "groupons" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "orders" ADD CONSTRAINT "fk_rails_560fbcca92" FOREIGN KEY ("gift_card_coupon_id") REFERENCES "gift_card_coupons" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "orders" ADD CONSTRAINT "fk_rails_6169843af0" FOREIGN KEY ("warehouse_order_id") REFERENCES "warehouse_orders" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "orders" ADD CONSTRAINT "fk_rails_8a74c1d8fa" FOREIGN KEY ("province_id") REFERENCES "provinces" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "orders" ADD CONSTRAINT "fk_rails_e80b9897bd" FOREIGN KEY ("promo_code_id") REFERENCES "promo_codes" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table push_message_read_logs
-- ----------------------------
ALTER TABLE "push_message_read_logs" ADD CONSTRAINT "fk_rails_63ec6e759c" FOREIGN KEY ("push_message_id") REFERENCES "push_messages" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "push_message_read_logs" ADD CONSTRAINT "fk_rails_f5052dea4f" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table push_messages
-- ----------------------------
ALTER TABLE "push_messages" ADD CONSTRAINT "fk_rails_497de496ae" FOREIGN KEY ("store_id") REFERENCES "stores" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "push_messages" ADD CONSTRAINT "fk_rails_638b40dbfd" FOREIGN KEY ("admin_user_id") REFERENCES "admin_users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table random_reduction_coupon_template_rules
-- ----------------------------
ALTER TABLE "random_reduction_coupon_template_rules" ADD CONSTRAINT "fk_rails_c30a5a2569" FOREIGN KEY ("coupon_template_id") REFERENCES "coupon_templates" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table sku_in_stock_notices
-- ----------------------------
ALTER TABLE "sku_in_stock_notices" ADD CONSTRAINT "fk_rails_107666c4d9" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "sku_in_stock_notices" ADD CONSTRAINT "fk_rails_30ae34eb53" FOREIGN KEY ("stock_keeping_unit_id") REFERENCES "stock_keeping_units" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table time_limited_promotion_prices
-- ----------------------------
ALTER TABLE "time_limited_promotion_prices" ADD CONSTRAINT "fk_rails_b69140dd91" FOREIGN KEY ("stock_keeping_unit_id") REFERENCES "stock_keeping_units" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "time_limited_promotion_prices" ADD CONSTRAINT "fk_rails_bc8130cbcf" FOREIGN KEY ("time_limited_promotion_id") REFERENCES "time_limited_promotions" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table time_limited_promotions
-- ----------------------------
ALTER TABLE "time_limited_promotions" ADD CONSTRAINT "fk_rails_09cf354899" FOREIGN KEY ("store_id") REFERENCES "stores" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table users
-- ----------------------------
ALTER TABLE "users" ADD CONSTRAINT "fk_rails_5545f72190" FOREIGN KEY ("selected_store_id") REFERENCES "stores" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table users_push_messages
-- ----------------------------
ALTER TABLE "users_push_messages" ADD CONSTRAINT "fk_rails_8ae9f272ea" FOREIGN KEY ("push_message_id") REFERENCES "push_messages" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "users_push_messages" ADD CONSTRAINT "fk_rails_bba7978038" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table warehouse_orders
-- ----------------------------
ALTER TABLE "warehouse_orders" ADD CONSTRAINT "fk_rails_41687c7a61" FOREIGN KEY ("store_id") REFERENCES "stores" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "warehouse_orders" ADD CONSTRAINT "fk_rails_d4835b3c13" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table web_banner_items
-- ----------------------------
ALTER TABLE "web_banner_items" ADD CONSTRAINT "fk_rails_4ac9973bc6" FOREIGN KEY ("web_banner_id") REFERENCES "web_banners" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table web_banners
-- ----------------------------
ALTER TABLE "web_banners" ADD CONSTRAINT "fk_rails_7017609e33" FOREIGN KEY ("store_id") REFERENCES "stores" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table web_custom_list_items
-- ----------------------------
ALTER TABLE "web_custom_list_items" ADD CONSTRAINT "fk_rails_a7f94ef0e6" FOREIGN KEY ("web_custom_list_id") REFERENCES "web_custom_lists" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "web_custom_list_items" ADD CONSTRAINT "fk_rails_f727fddd28" FOREIGN KEY ("item_id") REFERENCES "items" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table web_custom_lists
-- ----------------------------
ALTER TABLE "web_custom_lists" ADD CONSTRAINT "fk_rails_c7ba8fb3c8" FOREIGN KEY ("store_id") REFERENCES "stores" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;
