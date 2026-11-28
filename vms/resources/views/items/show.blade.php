@extends('layouts.vendor')
@section('title',__('商品详情'))
@section('content')
<div class="row"><h1>{{ $item->title }} <span class="badge b-{{ $item->status }}">{{ $item->statusLabel() }}</span></h1>
<span class="right row">
  @if($item->editableByVendor())<a class="btn" href="{{ url('/vms/items/'.$item->id.'/edit') }}">{{ __('编辑') }}</a>@elseif($item->limitedEditableByVendor())<a class="btn" href="{{ url('/vms/items/'.$item->id.'/edit') }}">{{ __('修改标题/图片') }}</a>@endif
  <form method="post" action="{{ url('/vms/items/export') }}">@csrf<input type="hidden" name="ids[]" value="{{ $item->id }}"><button class="btn sec">{{ __('导出 xlsx') }}</button></form>
  @if($item->status==='draft')<form method="post" action="{{ url('/vms/items/'.$item->id) }}" onsubmit="return confirm('{{ __('确认删除草稿?') }}')">@csrf @method('DELETE')<button class="btn bad">{{ __('删除') }}</button></form>@endif
</span></div>
@if($item->status==='returned')<div class="msg err">{{ __('退回原因:') }}{{ $item->return_reason }}</div>@endif
<div class="card"><table>@foreach($fields as $f)@if($item->val($f['key']) !== null && $item->val($f['key']) !== '')<tr><th style="width:240px">{{ __($f['label']) }}</th><td>{{ $item->val($f['key']) }}</td></tr>@endif @endforeach</table></div>
<div class="card"><h2>{{ __('图片') }}</h2>
@foreach(config('vms.image_kinds') as $kind => $spec)<div class="muted">{{ __($spec['label']) }}</div><div class="thumbs">@foreach($item->images->where('kind',$kind) as $img)<figure><a class="zoom" href="{{ $img->display_url }}" data-caption="{{ __($spec['label']) }} · {{ $img->width }}×{{ $img->height }} · {{ $img->original_name }}"><img src="{{ $img->display_url }}" alt=""><div class="muted">{{ $img->width }}×{{ $img->height }}</div></a></figure>@endforeach</div>@endforeach</div>
<h2>{{ __('状态历史') }}</h2>
<table><tr><th>{{ __('时间') }}</th><th>{{ __('状态变化') }}</th><th>{{ __('说明') }}</th><th>{{ __('操作人') }}</th></tr>
@foreach($item->histories as $h)<tr><td>{{ $h->created_at->format('Y-m-d H:i') }}</td><td>{{ __(\App\Models\Item::STATUS[$h->from_status] ?? '—') }} → {{ __(\App\Models\Item::STATUS[$h->to_status] ?? $h->to_status) }}</td><td>{{ __($h->note) }}</td><td>{{ $h->actor }}</td></tr>@endforeach</table>
@include('items._lightbox')
@endsection
