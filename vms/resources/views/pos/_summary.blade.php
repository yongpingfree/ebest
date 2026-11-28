@if($po->status==='exception')<div class="msg err">{{ __('仓库审核数量与实际不一致:') }}<br>{!! nl2br(e($po->exception_note)) !!}</div>@endif
<div class="card"><div class="cols">
<div><b>{{ __('供货商名称') }}</b><br>{{ $po->vendor_name }}</div><div><b>{{ __('WMS 采购单号') }}</b><br>{{ $po->wms_po_no ?: __('待运营回填') }}</div>
<div><b>{{ __('配送方式') }}</b><br>{{ __(config('vms.delivery_modes.'.$po->delivery_mode)) }}</div><div><b>{{ __('采购日期') }}</b><br>{{ $po->purchase_date->format('Y-m-d') }}</div>
<div><b>{{ __('采购人') }}</b><br>{{ $po->purchaser }}</div><div><b>{{ __('营销模式') }}</b><br>{{ __($po->marketing_mode) }}</div>
<div><b>{{ __('预计到货时间') }}</b><br>{{ $po->eta_date->format('Y-m-d') }}</div><div><b>{{ __('是否同步库存') }}</b><br>{{ $po->sync_stock ? __('是') : __('否') }}</div>
<div><b>{{ __('参考号') }}</b><br>{{ $po->reference_no }}</div></div>@if($po->note)<p>{{ __('备注:') }}{{ $po->note }}</p>@endif</div>
<table><tr><th>{{ __('产品名称') }}</th><th>SKU</th><th>{{ __('条形码') }}</th><th class="num">{{ __('数量') }}</th><th class="num">{{ __('含税单价') }}</th><th class="num">GST</th><th class="num">{{ __('小计') }}</th><th class="num">{{ __('实际到库') }}</th><th>{{ __('标注') }}</th></tr>
@foreach($po->lines as $l)<tr><td>{{ $l->product_name }}</td><td>{{ $l->sku_no }}</td><td>{{ $l->barcode }}</td><td class="num">{{ $l->qty }}</td><td class="num">{{ number_format($l->unit_price,2) }}</td><td class="num">{{ (float)$l->gst_rate }}%</td><td class="num">{{ number_format($l->subtotal,2) }}</td><td class="num">{{ $l->approved_qty ?? '—' }}</td><td>{{ $l->price_note }} {{ $l->pack_note }}</td></tr>@endforeach
<tr><th colspan="6" class="num">{{ __('合计') }}</th><th class="num">{{ number_format($po->total,2) }}</th><th colspan="2"></th></tr></table>
<h2>{{ __('状态历史') }}</h2>
<table><tr><th>{{ __('时间') }}</th><th>{{ __('状态') }}</th><th>{{ __('说明') }}</th><th>{{ __('操作人') }}</th></tr>
@foreach($po->histories as $h)<tr><td>{{ $h->created_at->format('Y-m-d H:i') }}</td><td>{{ __(\App\Models\PurchaseOrder::STATUS[$h->from_status] ?? '—') }} → {{ __(\App\Models\PurchaseOrder::STATUS[$h->to_status] ?? $h->to_status) }}</td><td>{{ __($h->note) }}</td><td>{{ $h->actor }}</td></tr>@endforeach</table>
