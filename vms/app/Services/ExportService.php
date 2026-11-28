<?php

namespace App\Services;

use App\Models\Item;
use App\Models\PurchaseOrder;
use PhpOffice\PhpSpreadsheet\IOFactory;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ExportService
{
    /** 按 import-items.xlsx 模板导出(第 1 行列名、第 2 行说明保持不变,数据从第 3 行开始) */
    public static function items($items, string $filename = 'import-items.xlsx'): StreamedResponse
    {
        $book = IOFactory::load(resource_path('templates/import-items.xlsx'));
        $ws = $book->getActiveSheet();
        $cols = [];
        for ($c = 1; $c <= 80; $c++) {
            $v = trim((string) $ws->getCell([$c, 1])->getValue());
            if ($v !== '') {
                $cols[$v] = $c;
            }
        }
        // 清除模板中可能存在的示例数据
        $last = $ws->getHighestRow();
        if ($last >= 3) {
            $ws->removeRow(3, $last - 2);
        }

        $row = 3;
        foreach ($items as $item) {
            /** @var Item $item */
            $item->loadMissing('images', 'vendor');
            $d = $item->data ?? [];
            $d['store_id'] = config('vms.store_id');
            $d['item_no'] = $item->oms_item_no ?: 'V'.$item->vendor_id.'-'.$item->id;
            $d['shoppingunit'] = $item->vendor->name;
            // 品牌:供应商选的是 VMS 品牌,导出时换成 eBest 回填的品牌 id(运营在商品页手填的 brand_id 优先)
            if (empty($d['brand_id']) && ! empty($d['brand_ref'])) {
                $d['brand_id'] = \App\Models\Brand::find($d['brand_ref'])?->ebest_brand_id;
            }
            foreach (['cover', 'share_cover', 'main_images', 'detail_images', 'sku_image'] as $kind) {
                $d[$kind] = $item->images->where('kind', $kind)->pluck('url')->implode(';');
            }
            foreach ($d as $key => $value) {
                if (isset($cols[$key]) && $value !== null && $value !== '') {
                    $ws->setCellValueExplicit([$cols[$key], $row], (string) $value, \PhpOffice\PhpSpreadsheet\Cell\DataType::TYPE_STRING);
                }
            }
            $row++;
        }

        return self::stream($book, $filename);
    }

    /** 采购单导出:Sheet1 WMS 批量导入模板;Sheet2 采购单模板;Sheet3 协作看板汇总 */
    public static function purchaseOrders($orders, string $filename): StreamedResponse
    {
        $book = new Spreadsheet();

        $wms = $book->getActiveSheet()->setTitle('模板文件');
        $wms->fromArray(['SKU', '产品', '数量', '价格', 'Include GST(Y/N)'], null, 'A1');
        $r = 2;
        foreach ($orders as $po) {
            foreach ($po->lines as $l) {
                $wms->fromArray([$l->sku_no, $l->product_name, $l->qty, (float) $l->unit_price, $l->gst_rate > 0 ? 'Y' : 'N'], null, "A$r");
                $wms->setCellValueExplicit("A$r", (string) $l->sku_no, \PhpOffice\PhpSpreadsheet\Cell\DataType::TYPE_STRING);
                $r++;
            }
        }

        $sheet = $book->createSheet()->setTitle('采购单');
        $r = 1;
        foreach ($orders as $po) {
            $head = [
                ['供货商名称', $po->vendor_name], ['purchase date', $po->purchase_date->format('Y-m-d')],
                ['purchaser', $po->purchaser], ['marketing mode', $po->marketing_mode],
                ['预计到货时间', $po->eta_date->format('Y-m-d')], ['是否同步库存', $po->sync_stock ? '是' : '否'],
            ];
            foreach ($head as $h) {
                $sheet->fromArray($h, null, "A$r");
                $r++;
            }
            $r++;
            $sheet->fromArray(['PRODUCT NAME', 'SKU', 'BARCODE', 'QTY', 'unit price (inc.GST)', 'GST rate', 'subtotal'], null, "A$r");
            $r++;
            foreach ($po->lines as $l) {
                $sheet->fromArray([$l->product_name, $l->sku_no, $l->barcode, $l->qty, (float) $l->unit_price, (float) $l->gst_rate.'%', (float) $l->subtotal], null, "A$r");
                $sheet->setCellValueExplicit("B$r", (string) $l->sku_no, \PhpOffice\PhpSpreadsheet\Cell\DataType::TYPE_STRING);
                $sheet->setCellValueExplicit("C$r", (string) $l->barcode, \PhpOffice\PhpSpreadsheet\Cell\DataType::TYPE_STRING);
                $r++;
            }
            $sheet->fromArray(['', '', '', '合计', '', '', (float) $po->total], null, "A$r");
            $r += 3;
        }

        $sum = $book->createSheet()->setTitle('协作看板汇总');
        $sum->fromArray(['草稿编号', 'WMS采购单号', '供货商名称', '预计到货时间', '产品总数量', '总额(inc.GST)'], null, 'A1');
        $r = 2;
        foreach ($orders as $po) {
            $sum->fromArray([$po->draft_no, $po->wms_po_no, $po->vendor_name, $po->eta_date->format('Y-m-d'), (int) $po->lines->sum('qty'), (float) $po->total], null, "A$r");
            $r++;
        }

        return self::stream($book, $filename);
    }

    private static function stream(Spreadsheet $book, string $filename): StreamedResponse
    {
        return response()->streamDownload(function () use ($book) {
            (new Xlsx($book))->save('php://output');
        }, $filename, ['Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']);
    }
}
