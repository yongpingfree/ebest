@extends('layouts.vendor')
@section('title', $item->exists ? '编辑商品' : '新增商品')
@section('content')
<h1>{{ $item->exists ? '编辑商品' : '新增商品' }} @if($item->exists)<span class="badge b-{{ $item->status }}">{{ $item->statusLabel() }}</span>@endif</h1>
@if($item->status==='returned')<div class="msg err">eBest 退回原因:{{ $item->return_reason }}</div>@endif
<form method="post" enctype="multipart/form-data" action="{{ $item->exists ? url('/vms/items/'.$item->id) : url('/vms/items') }}">
@csrf @if($item->exists) @method('PUT') @endif
@foreach(collect($fields)->groupBy('group') as $group => $gf)
<div class="card"><h2>{{ $group }}</h2><div class="cols">
  @foreach($gf as $f) @include('items._field', ['f'=>$f,'item'=>$item]) @endforeach
</div></div>
@endforeach
@unless($item->exists)
<div class="card" id="images"><h2>商品图片</h2>
  <p class="muted" style="margin:0 0 6px">可在此选择图片,点击「保存草稿」时一并上传;尺寸不符时会弹出裁剪窗口。也可保存草稿后再上传。</p>
@foreach(config('vms.image_kinds') as $kind => $spec)
  <h3 style="margin:14px 0 6px">{{ $spec['label'] }} @if($spec['required'])<span class="req" style="color:#c62828">*</span>@endif <span class="muted">{{ $spec['hint'] }}</span></h3>
  <input type="file" name="new_images[{{ $kind }}][]" data-trim-kind="{{ $kind }}" accept="image/*" style="max-width:340px" @if(!$spec['single']) multiple @endif>
@endforeach
</div>
@endunless
<div class="row">
  <button class="btn" name="action" value="save">保存草稿</button>
  @if($item->exists)<button class="btn ok" name="action" value="submit">保存并提交</button>@endif
  <a class="btn sec" href="{{ url('/vms/items') }}">返回</a>
</div>
</form>

@if($item->exists)
<div class="card" id="images" style="margin-top:18px"><h2>商品图片</h2>
@foreach(config('vms.image_kinds') as $kind => $spec)
  <h3 style="margin:14px 0 6px">{{ $spec['label'] }} @if($spec['required'])<span class="req" style="color:#c62828">*</span>@endif <span class="muted">{{ $spec['hint'] }};尺寸不符时可在线裁剪</span></h3>
  <div class="thumbs">
  @foreach($item->images->where('kind',$kind) as $img)
    <figure><img src="{{ $img->display_url }}" alt=""><div>{{ $img->width }}×{{ $img->height }}</div>
    <form method="post" action="{{ url('/vms/items/'.$item->id.'/images/'.$img->id) }}">@csrf @method('DELETE')<button class="btn sm bad">删除</button></form></figure>
  @endforeach
  </div>
  <form method="post" enctype="multipart/form-data" action="{{ url('/vms/items/'.$item->id.'/images') }}" class="row" style="margin-top:6px">
    @csrf <input type="hidden" name="kind" value="{{ $kind }}">
    <input type="file" name="images[]" data-trim-kind="{{ $kind }}" accept="image/*" style="max-width:340px" @if(!$spec['single'])multiple @endif required>
    <button class="btn sm sec">上传</button>
  </form>
@endforeach
</div>
@endif
@include('items._trim')
@endsection
