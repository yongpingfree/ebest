SELECT
	t1.product_id,
	t1.item_no AS '導入編號',
	t1.created_at AS "產品創建時間",
	t1.p_category AS '一級分類',
	t1.c_category AS '二級分類',
	t1.gmv_sku_level AS 'GMV等級',
	t1.gp_sku_level AS 'GP等級',
	t1.sku AS '貨號',
	t1.barcode AS '條形碼',
	t1.title AS '標題',
	t1.listing_type AS '產品販售狀態',
	t1.on_sale AS '上架',
	t1.is_special AS '特品',
	t1.sku_spec AS 'SKU規格',
	t1.marketing_mode AS '營銷模式',
	t1.is_virtual AS '虛擬商品',
	t1.shoppingunit AS '入駐商',
	t1.quantity AS 'OMS可販售庫存',
	t1.on_hold_quantity AS 'OMS待同步WMS庫存',
	t1.gift_quantity AS 'OMS贈品數量',
	t2.Jerry_Qty AS 'Jerry庫存',
	t4.Runbow_Qty AS 'Runbow庫存',
	t1.strikethrough_price AS '划線價',
	t1.price AS '售價',
	t5.inc_gst AS '是否有GST',
	t5.price_no_gst AS '採購金額(不含GST)',
	t5.gst AS 'GST',
	t5.price_no_gst + t5.gst AS '採購金額(含GST)',
	CONVERT(VARCHAR(10),t5.approve_date,23) AS '最近一次審貨日期',
	t3.sales_7 AS '最近7天銷量',
	t3.sales_14 AS '最近14天銷量',
	t3.sales_28 AS '最近28天銷量',
	t3.after_sales_7 AS '最近7天退貨',
	t3.after_sales_14 AS '最近14天退貨',
	t3.after_sales_28 AS '最近28天退貨',
	multi_sku.multi_sku
	
FROM
	ebest_item_master t1 (NOLOCK)
LEFT JOIN jerry_soh t2 (NOLOCK) ON t2.product_id = t1.product_id
LEFT JOIN sales_after_sales_record t3 (NOLOCK) ON t3.stock_keeping_unit_id = t1.product_id
LEFT JOIN 
(SELECT 
	sku.product_id,
	SUM(inv.Qty) AS Runbow_Qty

	FROM WMS_Inventory inv (NOLOCK)
	LEFT JOIN WMS_Client_SKU sku (NOLOCK) ON sku.SKU=inv.SKU

	WHERE
	inv.CustomerName = 'xianlvniubi6666'--IN ('xianlvniubi6666','EBEST BRISBANE')
	and inv.InventoryType = 1 --1可用庫存, 2操作中, 3凍結庫存
	and inv.Qty > 0

	GROUP BY
	sku.product_id
) t4 ON t4.product_id = t1.product_id
  LEFT JOIN latest_purchase_price t5 (NOLOCK) ON t5.product_id = t1.product_id
	LEFT JOIN 
 (
 SELECT
	item_no,
	't' AS multi_sku
FROM
	ebest_item_master (NOLOCK)
GROUP BY
	item_no
HAVING
	COUNT(product_id) > 1
	
UNION ALL

SELECT
	item_no,
	'f' AS multi_sku
FROM
	ebest_item_master (NOLOCK)
GROUP BY
	item_no
HAVING
	COUNT(product_id) = 1
	) multi_sku ON multi_sku.item_no = t1.item_no

WHERE
t1.store_id = 2 --IN (2,4)

ORDER BY
t1.store_id,t1.p_category,t1.c_category,t1.sku