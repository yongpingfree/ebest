@extends('layouts.staff')
@section('title','商品处理')
@section('content')
<div class="row"><h1>{{ $item->title }} <span class="badge b-{{ $item->status }}">{{ $item->statusLabel() }}</span></h1><span class="muted">{{ $item->vendor->name }}</span></div>
@if($item->post_listing_changed_at)
<div class="msg warn">供应商于 {{ $item->post_listing_changed_at->format('Y-m-d H:i') }} 在上架后修改了标题或图片(见下方状态历史)。请在 OMS 同步后点击
<form method="post" action="{{ url('/vms/staff/items/'.$item->id.'/synced') }}" style="display:inline">@csrf<button class="btn sm ok">已同步,清除标记</button></form></div>
@endif
<div class="card"><table>@foreach($vendorFields as $f)@if($item->val($f['key']) !== null && $item->val($f['key']) !== '')<tr><th style="width:240px">{{ $f['label'] }}</th><td>{{ $item->val($f['key']) }}</td></tr>@endif @endforeach</table></div>
<div class="card"><h2>图片</h2>@foreach(config('vms.image_kinds') as $kind=>$spec)<div class="muted">{{ $spec['label'] }}</div><div class="thumbs">@foreach($item->images->where('kind',$kind) as $img)<figure><a class="zoom" href="{{ $img->display_url }}" data-caption="{{ $spec['label'] }} · {{ $img->width }}×{{ $img->height }} · {{ $img->original_name }}"><img src="{{ $img->display_url }}" alt=""></a><div>{{ $img->width }}×{{ $img->height }}</div></figure>@endforeach</div>@endforeach</div>
<div class="card"><h2>运营填写字段(导出时写入 import-items.xlsx)</h2>
<form method="post" action="{{ url('/vms/staff/items/'.$item->id.'/ops') }}">@csrf<div class="cols">
@foreach($opsFields as $f)<div><label>{{ $f['label'] }}</label><input type="text" name="{{ $f['key'] }}" value="{{ $item->val($f['key']) }}"></div>@endforeach
<div><label>OMS 导入编号(item_no,留空自动生成)</label><input type="text" name="oms_item_no" value="{{ $item->oms_item_no }}"></div></div>
<p><button class="btn">保存</button></p></form></div>
<div class="card"><h2>处理</h2><div class="row">
@if(in_array($item->status,['submitted']))<form method="post" action="{{ url('/vms/staff/items/'.$item->id.'/mark/imported') }}">@csrf<button class="btn">标记为「已导入 OMS」</button></form>@endif
@if(in_array($item->status,['submitted','imported']))<form method="post" action="{{ url('/vms/staff/items/'.$item->id.'/mark/listed') }}">@csrf<button class="btn ok">标记为「已上架」</button></form>@endif
</div>
@if(in_array($item->status,['submitted','imported']))
<form method="post" action="{{ url('/vms/staff/items/'.$item->id.'/return') }}" class="row" style="margin-top:10px">@csrf<input type="text" name="reason" placeholder="退回原因(必填)" style="width:420px"><button class="btn bad">退回供应商</button></form>@endif</div>
<h2>状态历史</h2>
<table><tr><th>时间</th><th>状态变化</th><th>说明</th><th>操作人</th></tr>@foreach($item->histories as $h)<tr><td>{{ $h->created_at->format('Y-m-d H:i') }}</td><td>{{ \App\Models\Item::STATUS[$h->from_status] ?? '—' }} → {{ \App\Models\Item::STATUS[$h->to_status] ?? $h->to_status }}</td><td>{{ $h->note }}</td><td>{{ $h->actor }}</td></tr>@endforeach</table>
@include('items._lightbox')
@endsection
