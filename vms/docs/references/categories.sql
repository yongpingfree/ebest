/*
 Navicat Premium Dump SQL

 Source Server         : eBest OMS 生產環境 (AWS)
 Source Server Type    : PostgreSQL
 Source Server Version : 170009 (170009)
 Source Host           : ebestprd.cvmog2guevqo.ap-southeast-2.rds.amazonaws.com:5432
 Source Catalog        : ebest_production
 Source Schema         : public

 Target Server Type    : PostgreSQL
 Target Server Version : 170009 (170009)
 File Encoding         : 65001

 Date: 27/11/2026 17:25:08
*/


-- ----------------------------
-- Table structure for categories
-- ----------------------------
DROP TABLE IF EXISTS "public"."categories";
CREATE TABLE "public"."categories" (
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
COMMENT ON COLUMN "public"."categories"."search_keywords" IS '搜索关键词, 用于提升搜索商品准确度';

-- ----------------------------
-- Indexes structure for table categories
-- ----------------------------
CREATE INDEX "index_categories_on_ae_drop_shipper_category_id" ON "public"."categories" USING btree (
  "ae_drop_shipper_category_id" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "index_categories_on_parent_id" ON "public"."categories" USING btree (
  "parent_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table categories
-- ----------------------------
ALTER TABLE "public"."categories" ADD CONSTRAINT "categories_pkey" PRIMARY KEY ("id");
