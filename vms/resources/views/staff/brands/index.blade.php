@extends('layouts.staff')
@section('title','品牌')
@section('content')
<h1>供应商品牌</h1>
<p class="muted">在 WMS/OMS 中建好品牌后,在此回填品牌编号。供应商录入商品时下拉显示「编号-名称」,导出 import-items 时会自动带入 brand_id。</p>
<form class="filter" method="get"><input type="text" name="q" value="{{ request('q') }}" placeholder="品牌名 / 供应商">
<select name="status"><option value="">全部</option><option value="missing" @selected(request('status')==='missing')>待回填编号</option><option value="done" @selected(request('status')==='done')>已回填</option></select><button class="btn sec">筛选</button></form>
<table><tr><th>图片</th><th>品牌名称</th><th>英文名</th><th>供应商</th><th>品牌编号</th><th></th></tr>
@forelse($brands as $b)<tr>
<td>@if($b->image_path)<a href="{{ $b->display_url }}" target="_blank"><img src="{{ $b->display_url }}" alt="" style="width:56px;height:56px;object-fit:contain"></a>@endif</td>
<td>{{ $b->name }}</td><td>{{ $b->name_en }}</td>
<td><a href="{{ url('/vms/staff/vendors/'.$b->vendor_id) }}">{{ $b->vendor?->display() }}</a></td>
<td><form method="post" action="{{ url('/vms/staff/brands/'.$b->id.'/id') }}" class="row">@csrf
<input type="text" name="ebest_brand_id" value="{{ $b->ebest_brand_id }}" style="width:120px" placeholder="品牌编号"><button class="btn sm">保存</button></form>
@if($b->ebest_brand_id_by)<div class="muted">{{ $b->ebest_brand_id_by }} {{ optional($b->ebest_brand_id_at)->format('Y-m-d H:i') }}</div>@endif</td><td></td></tr>
@empty<tr><td colspan="6" class="muted">没有品牌</td></tr>@endforelse</table>
<div class="pager">{{ $brands->links() }}</div>
@endsection
