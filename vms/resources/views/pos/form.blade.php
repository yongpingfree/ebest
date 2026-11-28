@extends('layouts.vendor')
@section('title',__('采购单'))
@section('content')
@php
$lastPrices = $lastPrices ?? [];
@endphp
<h1>{{ $po->exists ? __('编辑采购单').' '.$po->draft_no : __('新建采购单') }}</h1>
<div class="msg warn">{{ __(config('vms.delivery_modes.'.$po->delivery_mode)) }}{{ __('。采购单只能包含「已上架」的商品;虚拟库存商品自动带出数量') }} {{ config('vms.virtual_qty') }}{{ __('、单价 0。') }}</div>
<form method="post" action="{{ $po->exists ? url('/vms/pos/'.$po->id) : url('/vms/pos') }}">
@csrf @if($po->exists) @method('PUT') @endif
<div class="card"><div class="cols">
  <div><label>{{ __('配送方式') }}</label><select name="delivery_mode">@foreach(config('vms.delivery_modes') as $m=>$l)<option value="{{ $m }}" @selected(old('delivery_mode',$po->delivery_mode)===$m)>{{ __($l) }}</option>@endforeach</select></div>
  <div><label>{{ __('供货商名称') }}</label><input type="text" value="{{ auth('vendor')->user()->name }}" disabled></div>
  <div><label>{{ __('采购日期') }} <span class="req">*</span></label><input type="date" name="purchase_date" value="{{ old('purchase_date', optional($po->purchase_date)->format('Y-m-d')) }}"></div>
  <div><label>{{ __('采购人') }} <span class="req">*</span></label><input type="text" name="purchaser" value="{{ old('purchaser',$po->purchaser) }}"></div>
  <div><label>{{ __('营销模式') }} <span class="req">*</span></label><select name="marketing_mode">@foreach(config('vms.marketing_modes') as $m)<option @selected(old('marketing_mode',$po->marketing_mode)===$m) value="{{ $m }}">{{ __($m) }}</option>@endforeach</select></div>
  <div><label>{{ __('预计到货时间') }} <span class="req">*</span></label><input type="date" name="eta_date" value="{{ old('eta_date', optional($po->eta_date)->format('Y-m-d')) }}"></div>
  <div><label>{{ __('是否同步库存') }} <span class="req">*</span></label><select name="sync_stock"><option value="1" @selected(old('sync_stock',$po->sync_stock?'1':'0')==='1')>{{ __('是') }}</option><option value="0" @selected(old('sync_stock',$po->sync_stock?'1':'0')==='0')>{{ __('否') }}</option></select></div>
  <div><label>{{ __('参考号(发票号;无则自动编号)') }}</label><input type="text" name="reference_no" value="{{ old('reference_no',$po->reference_no) }}"></div>
</div>
<label>{{ __('备注') }}</label><textarea name="note">{{ old('note',$po->note) }}</textarea></div>

<div class="card"><h2>{{ __('采购明细') }}</h2>
<table id="lines"><tr><th style="width:34%">{{ __('商品') }}</th><th>{{ __('条形码') }}</th><th>{{ __('数量') }}</th><th>{{ __('含税单价') }}</th><th class="num">GST</th><th class="num">{{ __('小计') }}</th><th>{{ __('价格变动标注 / 箱规说明') }}</th><th></th></tr>
@php
$rows = old('lines') ? collect(old('lines')) : $lines->map(fn($l)=>['item_id'=>$l->item_id,'qty'=>$l->qty,'unit_price'=>$l->unit_price,'barcode'=>$l->barcode,'price_note'=>$l->price_note,'pack_note'=>$l->pack_note])->values();
@endphp
@foreach($rows->push(['item_id'=>null])->all() as $n => $row)
<tr class="line">
 <td><select name="lines[{{ $n }}][item_id]" class="it"><option value="">{{ __('— 选择商品 —') }}</option>
  @foreach($items as $it)<option value="{{ $it->id }}" data-price="{{ $it->val('price_in_yuan') }}" data-gst="{{ $it->val('gst_percent',10) }}" data-bc="{{ $it->val('barcode') }}" data-virtual="{{ $it->val('is_virtual')==='是'?1:0 }}" @selected(($row['item_id']??null)==$it->id)>{{ $it->sku_no }} · {{ \Illuminate\Support\Str::limit($it->title,40) }}</option>@endforeach</select></td>
 <td><input type="text" name="lines[{{ $n }}][barcode]" value="{{ $row['barcode'] ?? '' }}" class="bc" style="width:140px" maxlength="64"></td>
 <td><input type="number" min="1" name="lines[{{ $n }}][qty]" value="{{ $row['qty'] ?? '' }}" class="qty" style="width:90px"></td>
 <td><input type="number" step="0.0001" min="0" name="lines[{{ $n }}][unit_price]" value="{{ $row['unit_price'] ?? '' }}" class="up" style="width:100px"></td>
 <td class="num gst"></td><td class="num sub">0.00</td>
 <td><input type="text" name="lines[{{ $n }}][price_note]" value="{{ $row['price_note'] ?? '' }}" placeholder="{{ __('价格变动原因') }}">
     <input type="text" name="lines[{{ $n }}][pack_note]" value="{{ $row['pack_note'] ?? '' }}" placeholder="{{ __('箱规说明(需拆箱时)') }}" style="margin-top:4px"></td>
 <td></td>
</tr>
@endforeach
<tr><th colspan="5" class="num">{{ __('合计(inc. GST)') }}</th><th class="num" id="total">0.00</th><th colspan="2"></th></tr>
</table>
<p class="muted">{{ __('将商品选到空白行后保存草稿,系统会自动追加新的空白行。上次采购单价不同时须填写价格变动标注。') }}</p>
</div>
<div class="row"><button class="btn" name="action" value="save">{{ __('保存草稿') }}</button><button class="btn ok" name="action" value="submit">{{ __('保存并提交') }}</button><a class="btn sec" href="{{ url('/vms/pos') }}">{{ __('返回') }}</a></div>
</form>
<script>
const VQ={{ (int) config('vms.virtual_qty') }};
function recalc(){let t=0;document.querySelectorAll('tr.line').forEach(r=>{const s=r.querySelector('.it'),o=s.selectedOptions[0];
 if(!o||!o.value){r.querySelector('.sub').textContent='0.00';return}
 r.querySelector('.gst').textContent=(o.dataset.gst||10)+'%';
 const q=r.querySelector('.qty'),u=r.querySelector('.up');
 if(o.dataset.virtual==='1'){q.value=VQ;u.value=0;q.readOnly=u.readOnly=true}else{q.readOnly=u.readOnly=false}
 const sub=(+q.value||0)*(+u.value||0);r.querySelector('.sub').textContent=sub.toFixed(2);t+=sub});
 document.getElementById('total').textContent=t.toFixed(2)}
document.querySelectorAll('tr.line .it').forEach(s=>s.addEventListener('change',e=>{const r=e.target.closest('tr'),o=e.target.selectedOptions[0];const u=r.querySelector('.up');if(o&&o.value&&!u.value)u.value=o.dataset.price||'';const b=r.querySelector('.bc');if(o&&o.value)b.value=o.dataset.bc||'';recalc()}));
document.querySelectorAll('.qty,.up').forEach(i=>i.addEventListener('input',recalc));recalc();
</script>
@endsection
