@extends('layouts.vendor')
@section('title','采购单')
@section('content')
<div class="row"><h1>采购单</h1><span class="right row">
@foreach(config('vms.delivery_modes') as $m => $l)<a class="btn {{ $loop->first ? '' : 'sec' }}" href="{{ url('/vms/pos/create?mode='.$m) }}" title="{{ $l }}">+ {{ ['vendor'=>'供应商配送','ebest'=>'eBest 配送','jit'=>'次日送仓'][$m] }}</a>@endforeach
</span></div>
<form class="filter" method="get"><select name="status"><option value="">全部状态</option>@foreach(\App\Models\PurchaseOrder::STATUS as $k=>$l)<option value="{{ $k }}" @selected(request('status')===$k)>{{ $l }}</option>@endforeach</select><button class="btn sec">筛选</button></form>
<table><tr><th>草稿编号</th><th>WMS 采购单号</th><th>配送方式</th><th>预计到货</th><th class="num">行数</th><th class="num">总额</th><th>状态</th><th></th></tr>
@forelse($pos as $p)<tr><td>{{ $p->draft_no }}</td><td>{{ $p->wms_po_no ?: '—' }}</td><td>{{ ['vendor'=>'供应商配送','ebest'=>'eBest 配送','jit'=>'次日送仓'][$p->delivery_mode] ?? $p->delivery_mode }}</td><td>{{ $p->eta_date->format('Y-m-d') }}</td><td class="num">{{ $p->lines_count }}</td><td class="num">{{ number_format($p->total,2) }}</td><td><span class="badge b-{{ $p->status }}">{{ $p->statusLabel() }}</span></td>
<td><a href="{{ url('/vms/pos/'.$p->id) }}">查看</a>@if($p->editableByVendor()) · <a href="{{ url('/vms/pos/'.$p->id.'/edit') }}">编辑</a>@endif</td></tr>
@empty<tr><td colspan="8" class="muted">还没有采购单</td></tr>@endforelse</table>
<div class="pager">{{ $pos->links() }}</div>
@endsection
