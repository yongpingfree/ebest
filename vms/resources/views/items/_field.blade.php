@php
  $k = $f['key'];
  $cur = old($k, $item->data[$k] ?? ($f['default'] ?? ''));
  $needed = $f['required'] || isset($f['required_if']);
@endphp
<div>
  <label>{{ $f['label'] }}@if($needed)<span class="req">*</span>@endif</label>
  @switch($f['type'])
    @case('textarea')<textarea name="{{ $k }}">{{ is_array($cur) ? implode(';', $cur) : $cur }}</textarea>@break
    @case('number')<input type="number" step="1" min="0" name="{{ $k }}" value="{{ $cur }}">@break
    @case('decimal')<input type="number" step="0.01" min="0" name="{{ $k }}" value="{{ $cur }}">@break
    @case('select')
    @case('yesno')
      <select name="{{ $k }}"><option value=""></option>
      @foreach($f['options'] as $o)<option value="{{ $o }}" @selected((string)$cur === (string)$o)>{{ $o }}</option>@endforeach
      </select>@break
    @case('multi')
      @php($sel = is_array($cur) ? $cur : array_filter(explode(';', (string) $cur)))
      <div class="row">@foreach($f['options'] as $o)
        <label style="font-weight:400;margin:0"><input type="checkbox" name="{{ $k }}[]" value="{{ $o }}" @checked(in_array($o, $sel))> {{ $o }}</label>
      @endforeach</div>@break
    @default<input type="text" name="{{ $k }}" value="{{ $cur }}" @if(!empty($f['placeholder']))placeholder="{{ $f['placeholder'] }}"@endif>
  @endswitch
</div>
