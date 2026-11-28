@extends('layouts.vendor')
@section('title', __('修改标题/图片'))
@section('content')
<div class="row"><h1>{{ $item->title }} <span class="badge b-{{ $item->status }}">{{ $item->statusLabel() }}</span></h1>
  <span class="right row"><a class="btn sec" href="{{ url('/vms/items/'.$item->id) }}">{{ __('返回') }}</a></span></div>
<div class="msg warn">{{ __('商品已导入 eBest 系统,只能修改标题和图片;价格、库存等其他信息如需变更请联系 eBest 运营。修改后运营会同步到商品系统。') }}</div>
@if($item->post_listing_changed_at)<div class="msg ok">{{ __('最近修改:') }}{{ $item->post_listing_changed_at->format('Y-m-d H:i') }}({{ __('等待 eBest 运营同步') }})</div>@endif
<form method="post" action="{{ url('/vms/items/'.$item->id) }}">@csrf @method('PUT')
<div class="card"><h2>{{ __('标题') }}</h2><div class="cols">
  @foreach($fields as $f) @include('items._field', ['f'=>$f,'item'=>$item]) @endforeach
</div>
<p><button class="btn">{{ __('保存标题') }}</button></p></div>
</form>
@include('items._images')
@include('items._trim')
@include('items._lightbox')
@endsection
