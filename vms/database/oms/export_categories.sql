-- 在 OMS 生产库(PostgreSQL)执行,导出全部分类和子分类(含 id 和名称),结果另存为 CSV(带表头,UTF-8)
-- 保存到 VMS 服务器 storage/app/categories/categories.csv,然后运行:php artisan vms:load-categories
-- 表结构见 docs/references/categories.sql 与 category_translations.sql。语言取值与 OMS 一致:zh-CN、en。
-- 在 Navicat/DBeaver 中导出:格式 CSV,编码 UTF-8,包含列标题;或用 psql:
--   psql "$OMS_DB_URL" -c "\copy (<下面的 SELECT>) TO 'categories.csv' WITH CSV HEADER"

SELECT c.id,
       c.parent_id,
       (SELECT t.name FROM category_translations t WHERE t.category_id = c.id AND t.locale = 'zh-CN' LIMIT 1) AS name_zh,
       (SELECT t.name FROM category_translations t WHERE t.category_id = c.id AND t.locale = 'en' LIMIT 1)    AS name_en,
       c.status,
       c.position
FROM categories c
ORDER BY COALESCE(c.parent_id, c.id), c.parent_id NULLS FIRST, c.position, c.id;
