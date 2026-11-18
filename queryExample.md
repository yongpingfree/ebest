ranbow query example

SELECT
	distinct odh.str2 AS "OMS訂單號"
-- 	LEFT(odh.str8,1) AS "路線",	
-- 	odh.str8 AS "車號",	
-- 	odh.ExternOrderNumber AS "Runbow訂單號",
-- 	CASE odh.ExpressCompany
-- 		WHEN 'eMetro WM' THEN '(派送)'
-- 		WHEN 'DOMESTIC EWE' THEN '(自提)'
-- 		ELSE '(eParcel)'
-- 	END AS "派送方式",
-- 	odh.str9 AS "下單來源",
-- 	odl.GoodsName AS "產品名稱",
-- 	c_sku.SKU AS "Runbow SKU",
-- 	itm.sku AS "OMS SKU",
-- 	odl.UPC,
-- 	odl.Area AS "庫區",
-- 	odl.Location AS "庫位",
-- 	odl.Qty	
	
FROM
	WMS_Order odh (NOLOCK)
LEFT JOIN WMS_OrderDetail odl (NOLOCK) ON odl.OID = odh.ID
LEFT JOIN WMS_Client_SKU c_sku ON c_sku.SKU = odl.SKU
LEFT JOIN ebest_item_master itm (NOLOCK) ON itm.product_id = c_sku.product_id

WHERE
	odh.CustomerName = 'xianlvniubi6666' 
  AND CONVERT(VARCHAR(100),odh.WaveTime,111) = CONVERT(VARCHAR(100),GETDATE(),111)
	and odl.GoodsName like '%oria%';

-- ORDER BY
-- 	odh.ExpressCompany,odh.str8;



--- getting customer details on oria orders

SELECT
    odh.str2 AS OrderNumber,                      -- the big number on the label
    odh.ExternOrderNumber AS EWEOrderNumber,      -- internal EWE no. (kept for reference)
    CASE odh.ExpressCompany
        WHEN 'eMetro WM' THEN '(Delivery)'
        WHEN 'DOMESTIC EWE' THEN '(Pick Up)'
        WHEN 'PARCEL POST + SIGNATURE' THEN '(eParcel)'
        WHEN 'FH EXPRESS' THEN 'FH EXPRESS'
        ELSE 'Other'
    END AS ExpressCompany,
    CONVERT(VARCHAR(10), odh.str5 + GETDATE() - GETUTCDATE(), 23) AS delivery_date,
    CONCAT(
        FORMAT(CONVERT(datetime2, odh.str5) AT TIME ZONE 'UTC' AT TIME ZONE 'AUS Eastern Standard Time', 'HH:mm'),
        ' - ',
        FORMAT(CONVERT(datetime2, odh.str6) AT TIME ZONE 'UTC' AT TIME ZONE 'AUS Eastern Standard Time', 'HH:mm')
    ) AS prefer_time,
    CASE odh.str7 WHEN 'true' THEN 'Yes' WHEN 'false' THEN 'No' END AS authority_to_leave,  -- ATL
    CASE WHEN odh.str1 LIKE '%' + CHAR(10) + '%' THEN 'Yes' END AS DeliveryToDoor,
    odh.Consignee,
    odh.Contact,
    cte.CleanedAddress AS Address,
    odh.str4 AS DeliveryNote,
    odd.Area,
    CONCAT(ISNULL(itm.short_title, itm.title), ' ', itm.sku_spec) AS GoodsName,
    CONCAT(itm.title_en, ' ', itm.sku_spec_en)                    AS GoodsNameEn,
    SUM(odd.Qty) AS Qty
FROM
    WMS_Order odh (NOLOCK)
    LEFT JOIN (
        SELECT ID,
            CASE WHEN Address IS NULL OR LEN(Address) = 0 THEN ''
                 ELSE REPLACE(REPLACE(REPLACE(REPLACE(SUBSTRING(Address,1,LEN(Address)-13),CHAR(10),''),' ','<>'),'><',''),'<>',' ')
            END AS CleanedAddress
        FROM WMS_Order
    ) cte ON cte.ID = odh.ID
    LEFT JOIN WMS_OrderDetail odd (NOLOCK)
        ON odd.OID = odh.ID AND odd.CustomerName = 'xianlvniubi6666'
    LEFT JOIN WMS_Warehouse_Location loc (NOLOCK)
        ON loc.Location = odd.Location
       AND loc.WarehouseID = (SELECT ID FROM WMS_Warehouse WHERE WarehouseName = '-')
    LEFT JOIN WMS_Client_SKU (NOLOCK)
        ON WMS_Client_SKU.SKU = odd.SKU
    LEFT JOIN ebest_item_master itm (NOLOCK)
        ON itm.product_id = WMS_Client_SKU.product_id
WHERE
    odh.CustomerName = 'xianlvniubi6666'
    AND odh.str2 IN ('W202611152050023281',
    'W202611152050167441',
    'W202611152050175370',
    'W202611152050193987',
    'W202611152050225041',
    'W202611152050361562',
    'W202611152050772035')
GROUP BY
    odh.str2,
    odh.ExternOrderNumber,
    odh.ExpressCompany,
    odh.str5,
    odh.str6,
    odh.str7,
    odh.str1,
    odh.Consignee,
    odh.Contact,
    cte.CleanedAddress,
    odh.str4,
    odd.Area,
    CONCAT(ISNULL(itm.short_title, itm.title), ' ', itm.sku_spec),
    CONCAT(itm.title_en, ' ', itm.sku_spec_en)
ORDER BY
    odh.str2,
    odd.Area;