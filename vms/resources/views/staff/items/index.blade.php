@extends('layouts.staff')
@section('title','商品')
@section('content')
<h1>供应商商品</h1>
<form class="filter" method="get"><input type="text" name="q" value="{{ request('q') }}" placeholder="标题或商品编码">
<select name="status"><option value="">全部(不含草稿)</option>@foreach(\App\Models\Item::STATUS as $k=>$l)<option value="{{ $k }}" @selected(request('status')===$k)>{{ $l }}</option>@endforeach</select><button class="btn sec">筛选</button></form>
<form method="post" action="{{ url('/vms/staff/items/export') }}">@csrf
<div class="row" style="margin-bottom:8px"><button class="btn">导出所选(未选则导出全部「已提交」) → import-items.xlsx</button></div>
<table><tr><th></th><th>供应商</th><th>商品编码</th><th>标题</th><th>状态</th><th>提交时间</th><th>已导出</th><th></th></tr>
@foreach($items as $i)<tr><td><input type="checkbox" name="ids[]" value="{{ $i->id }}"></td><td>{{ $i->vendor->name }}</td><td>{{ $i->sku_no }}</td><td>{{ $i->title }}</td><td><span class="badge b-{{ $i->status }}">{{ $i->statusLabel() }}</span></td><td>{{ optional($i->submitted_at)->format('Y-m-d H:i') }}</td><td>{{ optional($i->exported_at)->format('m-d H:i') }}</td><td><a href="{{ url('/vms/staff/items/'.$i->id) }}">处理</a></td></tr>@endforeach</table></form>
<div class="pager">{{ $items->links() }}</div>
@endsection
