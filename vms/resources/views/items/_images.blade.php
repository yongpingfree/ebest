<div class="card" id="images" style="margin-top:18px"><h2>{{ __('商品图片') }}</h2>
@foreach(config('vms.image_kinds') as $kind => $spec)
  <h3 style="margin:14px 0 6px">{{ __($spec['label']) }} @if($spec['required'])<span class="req" style="color:#c62828">*</span>@endif <span class="muted">{{ __($spec['hint']) }}{{ __(';尺寸不符时可在线裁剪') }}</span></h3>
  <div class="thumbs">
  @foreach($item->images->where('kind',$kind) as $img)
    <figure><a class="zoom" href="{{ $img->display_url }}" data-caption="{{ __($spec['label']) }} · {{ $img->width }}×{{ $img->height }} · {{ $img->original_name }}"><img src="{{ $img->display_url }}" alt=""></a><div>{{ $img->width }}×{{ $img->height }}</div>
    <form method="post" action="{{ url('/vms/items/'.$item->id.'/images/'.$img->id) }}">@csrf @method('DELETE')<button class="btn sm bad">{{ __('删除') }}</button></form></figure>
  @endforeach
  </div>
  <form method="post" enctype="multipart/form-data" action="{{ url('/vms/items/'.$item->id.'/images') }}" class="row" style="margin-top:6px">
    @csrf <input type="hidden" name="kind" value="{{ $kind }}">
    <input type="file" name="images[]" data-trim-kind="{{ $kind }}" accept="image/*" style="max-width:340px" @if(!$spec['single'])multiple @endif required>
    <button class="btn sm sec">{{ __('上传') }}</button>
  </form>
@endforeach
</div>
