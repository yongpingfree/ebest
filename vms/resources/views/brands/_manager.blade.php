<div class="card" id="brands">
  <h2>{{ __('品牌') }} <span class="req">*</span></h2>
  <p class="muted">{{ __('至少创建一个品牌并上传品牌图片。品牌创建后由 eBest 在系统中建档并回填品牌编号,编号出现后品牌名称不能再修改。') }}</p>
  @if($errors->has('brand'))<div class="msg err">{{ $errors->first('brand') }}</div>@endif
  @forelse($brands as $b)
  <div class="row" style="align-items:flex-start;border-top:1px solid #eee;padding:10px 0">
    @if($b->image_path)<img src="{{ $b->display_url }}" alt="" style="width:80px;height:80px;object-fit:contain;border:1px solid #ddd;border-radius:4px;margin-right:12px">@endif
    <form method="post" action="{{ url('/vms/brands/'.$b->id) }}" enctype="multipart/form-data" class="row" style="flex:1">@csrf
      <div><label>{{ __('品牌名称') }}</label><input type="text" name="name" value="{{ $b->name }}" @readonly($b->ebest_brand_id)></div>
      <div><label>{{ __('品牌英文名') }}</label><input type="text" name="name_en" value="{{ $b->name_en }}"></div>
      <div><label>{{ __('更换图片') }}</label><input type="file" name="image" accept="image/*"></div>
      <div><label>&nbsp;</label><button class="btn sm">{{ __('保存') }}</button></div>
    </form>
    <div style="min-width:150px">
      <div class="muted">{{ __('eBest 品牌编号') }}:{{ $b->ebest_brand_id ?: __('待 eBest 回填') }}</div>
      @unless($b->ebest_brand_id)
      <form method="post" action="{{ url('/vms/brands/'.$b->id) }}" onsubmit="return confirm('{{ __('确认删除该品牌?') }}')">@csrf @method('DELETE')<button class="btn sm bad">{{ __('删除') }}</button></form>
      @endunless
    </div>
  </div>
  @empty
  <div class="msg warn">{{ __('还没有品牌,请先添加至少一个。') }}</div>
  @endforelse
  <h3 style="margin-top:14px">{{ __('添加品牌') }}</h3>
  <form method="post" action="{{ url('/vms/brands') }}" enctype="multipart/form-data" class="row">@csrf
    <div><label>{{ __('品牌名称') }} <span class="req">*</span></label><input type="text" name="name" required></div>
    <div><label>{{ __('品牌英文名') }}</label><input type="text" name="name_en"></div>
    <div><label>{{ __('品牌图片') }} <span class="req">*</span></label><input type="file" name="image" accept="image/*" required></div>
    <div><label>&nbsp;</label><button class="btn">{{ __('添加') }}</button></div>
  </form>
</div>
