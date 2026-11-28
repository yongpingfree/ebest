@extends('layouts.vendor')
@section('title', $item->exists ? __('编辑商品') : __('新增商品'))
@section('content')
<h1>{{ $item->exists ? __('编辑商品') : __('新增商品') }} @if($item->exists)<span class="badge b-{{ $item->status }}">{{ $item->statusLabel() }}</span>@endif</h1>
@if($item->status==='returned')<div class="msg err">{{ __('eBest 退回原因:') }}{{ $item->return_reason }}</div>@endif
<form method="post" enctype="multipart/form-data" action="{{ $item->exists ? url('/vms/items/'.$item->id) : url('/vms/items') }}">
@csrf @if($item->exists) @method('PUT') @endif
@foreach(collect($fields)->groupBy('group') as $group => $gf)
<div class="card"><h2>{{ __($group) }}</h2><div class="cols">
  @foreach($gf as $f) @include('items._field', ['f'=>$f,'item'=>$item]) @endforeach
</div></div>
@endforeach
@unless($item->exists)
<div class="card" id="images"><h2>{{ __('商品图片') }}</h2>
  <p class="muted" style="margin:0 0 6px">{{ __('可在此选择图片,点击「保存草稿」时一并上传;尺寸不符时会弹出裁剪窗口。也可保存草稿后再上传。') }}</p>
@foreach(config('vms.image_kinds') as $kind => $spec)
  <h3 style="margin:14px 0 6px">{{ __($spec['label']) }} @if($spec['required'])<span class="req" style="color:#c62828">*</span>@endif <span class="muted">{{ __($spec['hint']) }}</span></h3>
  <input type="file" name="new_images[{{ $kind }}][]" data-trim-kind="{{ $kind }}" accept="image/*" style="max-width:340px" @if(!$spec['single']) multiple @endif>
@endforeach
</div>
@endunless
<div class="row">
  <button class="btn" name="action" value="save">{{ __('保存草稿') }}</button>
  @if($item->exists)<button class="btn ok" name="action" value="submit">{{ __('保存并提交') }}</button>@endif
  <a class="btn sec" href="{{ url('/vms/items') }}">{{ __('返回') }}</a>
</div>
</form>

@if($item->exists)
@include('items._images')
@endif
@include('items._trim')
@include('items._lightbox')
<script>
(function () {
  var tree = {!! json_encode($catChildren ?? new \stdClass, JSON_UNESCAPED_UNICODE) !!};
  var parent = document.getElementById('catParent'), child = document.getElementById('catChild');
  if (!parent || !child) return;
  var pick = {!! json_encode(__('— 请选择子分类 —'), JSON_UNESCAPED_UNICODE) !!}, first = {!! json_encode(__('— 请先选择分类 —'), JSON_UNESCAPED_UNICODE) !!};
  function fill(selected) {
    var list = tree[parent.value] || [];
    child.innerHTML = '';
    var o = document.createElement('option'); o.value = ''; o.textContent = parent.value ? pick : first; child.appendChild(o);
    list.forEach(function (c) {
      var op = document.createElement('option'); op.value = c.id; op.textContent = c.label;
      if (String(c.id) === String(selected)) op.selected = true;
      child.appendChild(op);
    });
  }
  parent.addEventListener('change', function () { fill(''); });
  fill(child.getAttribute('data-selected'));
})();
</script>
@endsection
