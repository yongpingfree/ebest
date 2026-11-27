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

 Date: 27/11/2026 17:25:19
*/


-- ----------------------------
-- Table structure for category_translations
-- ----------------------------
DROP TABLE IF EXISTS "public"."category_translations";
CREATE TABLE "public"."category_translations" (
  "id" int8 NOT NULL DEFAULT nextval('category_translations_id_seq'::regclass),
  "category_id" int8 NOT NULL,
  "locale" varchar COLLATE "pg_catalog"."default" NOT NULL,
  "created_at" timestamp(6) NOT NULL,
  "updated_at" timestamp(6) NOT NULL,
  "name" varchar COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Indexes structure for table category_translations
-- ----------------------------
CREATE INDEX "index_category_translations_on_category_id" ON "public"."category_translations" USING btree (
  "category_id" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE INDEX "index_category_translations_on_locale" ON "public"."category_translations" USING btree (
  "locale" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Primary Key structure for table category_translations
-- ----------------------------
ALTER TABLE "public"."category_translations" ADD CONSTRAINT "category_translations_pkey" PRIMARY KEY ("id");
