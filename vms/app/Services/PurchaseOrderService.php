<?php

namespace App\Services;

use App\Models\Item;
use App\Models\PurchaseOrder;
use App\Models\PurchaseOrderLine;
use App\Models\Vendor;

class PurchaseOrderService
{
    /** 只有已上架的本供应商商品可以进入采购单(FR-5.7) */
    public static function selectableItems(Vendor $vendor)
    {
        return $vendor->items()->where('status', 'listed')->orderBy('sku_no')->get();
    }

    public static function nextDraftNo(Vendor $vendor): string
    {
        $n = PurchaseOrder::where('vendor_id', $vendor->id)->whereDate('created_at', today())->count() + 1;

        return sprintf('VPO-%d-%s-%02d', $vendor->id, today()->format('Ymd'), $n);
    }

    /** 参考号:无发票号时按"年月日加两位序号"自动编写 */
    public static function autoReference(Vendor $vendor): string
    {
        $n = PurchaseOrder::where('vendor_id', $vendor->id)->whereDate('created_at', today())->count() + 1;

        return today()->format('Ymd').sprintf('%02d', $n);
    }

    /** 同一供应商同一商品的上一次采购单价 */
    public static function lastPrice(Vendor $vendor, ?string $sku, ?int $exceptPo = null): ?float
    {
        if (! $sku) {
            return null;
        }
        $line = PurchaseOrderLine::whereHas('purchaseOrder', function ($q) use ($vendor, $exceptPo) {
            $q->where('vendor_id', $vendor->id)->whereIn('status', ['submitted', 'approved']);
            if ($exceptPo) {
                $q->where('id', '!=', $exceptPo);
            }
        })->where('sku_no', $sku)->latest('id')->first();

        return $line ? (float) $line->unit_price : null;
    }

    /** 保存采购单行。$rows 为请求中的明细数组 */
    public static function saveLines(PurchaseOrder $po, array $rows): void
    {
        $po->lines()->delete();
        $total = 0;
        foreach ($rows as $row) {
            if (empty($row['item_id'])) {
                continue;
            }
            $item = Item::where('vendor_id', $po->vendor_id)->where('status', 'listed')->find($row['item_id']);
            if (! $item) {
                continue;
            }
            $virtual = $item->val('is_virtual') === '是';
            $qty = $virtual ? (int) config('vms.virtual_qty') : max((int) ($row['qty'] ?? 0), 0);
            $price = $virtual ? 0.0 : round((float) ($row['unit_price'] ?? 0), 4);
            $gst = $item->val('gst_percent') !== null ? (float) $item->val('gst_percent') : (float) ($row['gst_rate'] ?? 10);
            $sub = round($qty * $price, 2);
            $total += $sub;
            $po->lines()->create([
                'item_id' => $item->id,
                'product_name' => $item->title,
                'sku_no' => $item->sku_no,
                'barcode' => $item->val('barcode'),
                'qty' => $qty, 'unit_price' => $price, 'gst_rate' => $gst, 'subtotal' => $sub,
                'price_note' => $row['price_note'] ?? null,
                'pack_note' => $row['pack_note'] ?? null,
            ]);
        }
        $po->update(['total' => round($total, 2)]);
    }

    public static function missingForSubmit(PurchaseOrder $po): array
    {
        $errors = [];
        foreach (['vendor_name' => '供货商名称', 'purchase_date' => '采购日期', 'purchaser' => '采购人', 'marketing_mode' => '营销模式', 'eta_date' => '预计到货时间'] as $f => $label) {
            if (empty($po->{$f})) {
                $errors[] = "「{$label}」为必填项";
            }
        }
        if ($po->lines->isEmpty()) {
            $errors[] = '采购单至少需要一行商品';
        }
        foreach ($po->lines as $l) {
            $name = $l->sku_no ?: $l->product_name;
            if ($l->qty < 1) {
                $errors[] = "{$name}:数量必须大于 0";
            }
            if (! $l->sku_no && ! $l->barcode) {
                $errors[] = "{$l->product_name}:商品编码与条形码至少填一个";
            }
            $virtual = $l->item && $l->item->val('is_virtual') === '是';
            if (! $virtual && (float) $l->unit_price <= 0) {
                $errors[] = "{$name}:含税单价必须大于 0";
            }
            $last = self::lastPrice($po->vendor, $l->sku_no, $po->id);
            if ($last !== null && abs($last - (float) $l->unit_price) > 0.00001 && ! $virtual && trim((string) $l->price_note) === '') {
                $errors[] = "{$name}:单价与上次采购单({$last})不同,请填写价格变动标注";
            }
        }
        // 营销模式须与商品一致
        foreach ($po->lines as $l) {
            $m = $l->item?->val('marketing_mode') ?: '自营';
            if ($l->item && $m !== $po->marketing_mode) {
                $errors[] = ($l->sku_no ?: $l->product_name).":商品营销模式为「{$m}」,与采购单「{$po->marketing_mode}」不一致";
            }
        }

        return $errors;
    }
}
