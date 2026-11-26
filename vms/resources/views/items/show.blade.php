@extends('layouts.vendor')
@section('title','商品详情')
@section('content')
<div class="row"><h1>{{ $item->title }} <span class="badge b-{{ $item->status }}">{{ $item->statusLabel() }}</span></h1>
<span class="right row">
  @if($item->editableByVendor())<a class="btn" href="{{ url('/vms/items/'.$item->id.'/edit') }}">编辑</a>@endif
  <form method="post" action="{{ url('/vms/items/export') }}">@csrf<input type="hidden" name="ids[]" value="{{ $item->id }}"><button class="btn sec">导出 xlsx</button></form>
  @if($item->status==='draft')<form method="post" action="{{ url('/vms/items/'.$item->id) }}" onsubmit="return confirm('确认删除草稿?')">@csrf @method('DELETE')<button class="btn bad">删除</button></form>@endif
</span></div>
@if($item->status==='returned')<div class="msg err">退回原因:{{ $item->return_reason }}</div>@endif
<div class="card"><table>@foreach($fields as $f)@if($item->val($f['key']) !== null && $item->val($f['key']) !== '')<tr><th style="width:240px">{{ $f['label'] }}</th><td>{{ $item->val($f['key']) }}</td></tr>@endif @endforeach</table></div>
<div class="card"><h2>图片</h2>
@foreach(config('vms.image_kinds') as $kind => $spec)<div class="muted">{{ $spec['label'] }}</div><div class="thumbs">@foreach($item->images->where('kind',$kind) as $img)<figure><img src="{{ $img->display_url }}" alt=""></figure>@endforeach</div>@endforeach</div>
<h2>状态历史</h2>
<table><tr><th>时间</th><th>状态变化</th><th>说明</th><th>操作人</th></tr>
@foreach($item->histories as $h)<tr><td>{{ $h->created_at->format('Y-m-d H:i') }}</td><td>{{ \App\Models\Item::STATUS[$h->from_status] ?? '—' }} → {{ \App\Models\Item::STATUS[$h->to_status] ?? $h->to_status }}</td><td>{{ $h->note }}</td><td>{{ $h->actor }}</td></tr>@endforeach</table>
@endsection
