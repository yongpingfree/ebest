@extends('layouts.staff')
@section('title','采购单')
@section('content')
<h1>供应商采购单</h1>
<form class="filter" method="get"><select name="status"><option value="">全部(不含草稿)</option>@foreach(\App\Models\PurchaseOrder::STATUS as $k=>$l)<option value="{{ $k }}" @selected(request('status')===$k)>{{ $l }}</option>@endforeach</select>
到货日期 <input type="date" name="from" value="{{ request('from') }}"> – <input type="date" name="to" value="{{ request('to') }}"><button class="btn sec">筛选</button></form>
<form method="post" action="{{ url('/vms/staff/pos/export') }}">@csrf
<div class="row" style="margin-bottom:8px"><button class="btn">导出所选(未选则导出「已提交且未回填 WMS 单号」) → 采购单批量导入 Excel</button></div>
<table><tr><th></th><th>草稿编号</th><th>供应商</th><th>配送方式</th><th>预计到货</th><th class="num">总额</th><th>WMS 单号</th><th>状态</th><th></th></tr>
@foreach($pos as $p)<tr><td><input type="checkbox" name="ids[]" value="{{ $p->id }}"></td><td>{{ $p->draft_no }}</td><td>{{ $p->vendor_name }}</td><td>{{ ['vendor'=>'供应商配送','ebest'=>'eBest 配送','jit'=>'次日送仓'][$p->delivery_mode] }}</td><td>{{ $p->eta_date->format('Y-m-d') }}</td><td class="num">{{ number_format($p->total,2) }}</td><td>{{ $p->wms_po_no ?: '—' }}</td><td><span class="badge b-{{ $p->status }}">{{ $p->statusLabel() }}</span></td><td><a href="{{ url('/vms/staff/pos/'.$p->id) }}">处理</a></td></tr>@endforeach</table></form>
<div class="pager">{{ $pos->links() }}</div>
@endsection
