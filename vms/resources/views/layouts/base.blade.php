<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>@yield('title', '供应商门户') - eBest VMS</title>
<link rel="stylesheet" href="{{ url('/vms/css/vms.css') }}?v=2">
</head>
<body>
<div class="top">
  <img src="{{ url('/vms/images/ebest.png') }}" alt="eBest">
  <span class="title">eBest 供应商管理系统 @yield('badge')</span>
  <span class="sp"></span>
  @yield('userbar')
</div>
@yield('body')
</body>
</html>
