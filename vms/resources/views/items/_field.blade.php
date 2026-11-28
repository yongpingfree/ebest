@php
  $k = $f['key'];
  $cur = old($k, $item->data[$k] ?? ($f['default'] ?? ''));
  $needed = $f['required'] || isset($f['required_if']);
@endphp
<div>
  <label>{{ __($f['label']) }}@if($needed)<span class="req">*</span>@endif</label>
  @switch($f['type'])
    @case('textarea')<textarea name="{{ $k }}">{{ is_array($cur) ? implode(';', $cur) : $cur }}</textarea>@break
    @case('number')<input type="number" step="1" min="0" name="{{ $k }}" value="{{ $cur }}">@break
    @case('decimal')<input type="number" step="0.01" min="0" name="{{ $k }}" value="{{ $cur }}">@break
    @case('date')
      @php($dv = preg_match('/^\d{4}-\d{2}-\d{2}$/', (string) $cur) ? $cur : '')
      <input type="date" name="{{ $k }}" value="{{ $dv }}">@break
    @case('datetime')
      @php($tv = preg_match('/^(\d{4}-\d{2}-\d{2})[ T](\d{2}:\d{2})/', (string) $cur, $tm) ? $tm[1].'T'.$tm[2] : '')
      <input type="datetime-local" name="{{ $k }}" value="{{ $tv }}">@break
    @case('brand')
      <select name="{{ $k }}"><option value="">{{ __('— 请选择品牌 —') }}</option>
      @foreach($brands as $b)<option value="{{ $b->id }}" @selected((string)$cur === (string)$b->id)>{{ $b->label() }}</option>@endforeach
      </select>
      @if($brands->isEmpty())<div class="muted">{{ __('请先在「品牌管理」中创建品牌') }}</div>@endif
      @break
    @case('category')
      <select name="{{ $k }}" id="catParent"><option value="">{{ __('— 请选择分类 —') }}</option>
      @foreach($catParents as $c)<option value="{{ $c->id }}" @selected((string)$cur === (string)$c->id)>{{ $c->label() }}</option>@endforeach
      </select>
      @if($catParents->isEmpty())<div class="muted">{{ __('分类数据尚未载入,请联系 eBest 运营') }}</div>@endif
      @break
    @case('subcategory')
      <select name="{{ $k }}" id="catChild" data-selected="{{ $cur }}"><option value="">{{ __('— 请先选择分类 —') }}</option></select>
      @break
    @case('select')
    @case('yesno')
      <select name="{{ $k }}"><option value=""></option>
      @foreach($f['options'] as $o)<option value="{{ $o }}" @selected((string)$cur === (string)$o)>{{ __($o) }}</option>@endforeach
      </select>@break
    @case('multi')
      @php($sel = is_array($cur) ? $cur : array_filter(explode(';', (string) $cur)))
      <div class="row">@foreach($f['options'] as $o)
        <label style="font-weight:400;margin:0"><input type="checkbox" name="{{ $k }}[]" value="{{ $o }}" @checked(in_array($o, $sel))> {{ __($o) }}</label>
      @endforeach</div>@break
    @default<input type="text" name="{{ $k }}" value="{{ $cur }}" @if(!empty($f['placeholder']))placeholder="{{ __($f['placeholder']) }}"@endif>
  @endswitch
</div>
