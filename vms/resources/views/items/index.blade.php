@extends('layouts.vendor')
@section('title','商品上架')
@section('content')
<div class="row"><h1>商品上架</h1>
  <span class="right row">
    <a class="btn sec" href="{{ url('/vms/items/export') }}">导出 import-items.xlsx</a>
    <a class="btn" href="{{ url('/vms/items/create') }}">+ 新增商品</a>
  </span></div>
<form class="filter" method="get">
  <input type="text" name="q" value="{{ request('q') }}" placeholder="标题或商品编码">
  <select name="status"><option value="">全部状态</option>
  @foreach(\App\Models\Item::STATUS as $k=>$l)<option value="{{ $k }}" @selected(request('status')===$k)>{{ $l }}</option>@endforeach</select>
  <button class="btn sec">筛选</button>
</form>
<table><tr><th>商品编码</th><th>标题</th><th>价格</th><th>库存</th><th>状态</th><th>更新时间</th><th></th></tr>
@forelse($items as $i)
<tr><td>{{ $i->sku_no }}</td><td>{{ $i->title }}</td><td>{{ $i->val('price_in_yuan') }}</td><td>{{ $i->val('quantity') }}</td>
<td><span class="badge b-{{ $i->status }}">{{ $i->statusLabel() }}</span>@if($i->status==='returned')<div class="muted">{{ $i->return_reason }}</div>@endif</td>
<td>{{ $i->updated_at->format('Y-m-d H:i') }}</td>
<td><a href="{{ url('/vms/items/'.$i->id) }}">查看</a>@if($i->editableByVendor()) · <a href="{{ url('/vms/items/'.$i->id.'/edit') }}">编辑</a>@endif</td></tr>
@empty<tr><td colspan="7" class="muted">还没有商品</td></tr>@endforelse
</table>
<div class="pager">{{ $items->links() }}</div>
@endsection
