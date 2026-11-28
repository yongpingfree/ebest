<!doctype html>
<html lang="{{ app()->getLocale() === 'en' ? 'en' : 'zh-CN' }}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>@yield('title', __('供应商门户')) - eBest VMS</title>
<link rel="stylesheet" href="{{ url('/vms/css/vms.css') }}?v=2">
</head>
<body>
<div class="top">
  <img src="{{ url('/vms/images/ebest.png') }}" alt="eBest">
  <span class="title">{{ __('eBest 供应商管理系统') }} @yield('badge')</span>
  <span class="sp"></span>
  @unless(request()->is('vms/staff', 'vms/staff/*'))
    <a class="linkbtn" href="{{ url('/vms/lang/'.(app()->getLocale() === 'en' ? 'zh' : 'en')) }}">{{ app()->getLocale() === 'en' ? '中文' : 'English' }}</a>
  @endunless
  @yield('userbar')
</div>
@yield('body')
</body>
</html>
