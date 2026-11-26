@extends('layouts.staff')
@section('title','采购单处理')
@section('content')
<div class="row"><h1>{{ $po->draft_no }} <span class="badge b-{{ $po->status }}">{{ $po->statusLabel() }}</span></h1></div>
@include('pos._summary', ['po'=>$po])
<div class="card"><h2>回填 WMS 采购单号</h2>
<form method="post" action="{{ url('/vms/staff/pos/'.$po->id.'/wms-no') }}" class="row">@csrf<input type="text" name="wms_po_no" value="{{ $po->wms_po_no }}" style="width:260px"><button class="btn">保存</button></form></div>
@if(in_array($po->status,['submitted','exception']))
<div class="card"><h2>仓库按实际到库数量审核</h2>
<form method="post" action="{{ url('/vms/staff/pos/'.$po->id.'/review') }}">@csrf
<table><tr><th>SKU</th><th>产品</th><th class="num">采购数量</th><th>实际到库数量</th></tr>
@foreach($po->lines as $l)<tr><td>{{ $l->sku_no }}</td><td>{{ $l->product_name }}</td><td class="num">{{ $l->qty }}</td><td><input type="number" min="0" name="qty[{{ $l->id }}]" value="{{ $l->approved_qty ?? $l->qty }}" style="width:110px"></td></tr>@endforeach</table>
<label>备注</label><input type="text" name="note"><p class="muted">数量全部一致 → 已审核;任一不一致 → 记为异常。审核与库存入账仍须在 WMS 完成。</p>
<button class="btn ok">提交审核结果</button></form></div>
@endif
@endsection
