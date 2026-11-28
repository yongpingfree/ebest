@extends('layouts.base')
@section('userbar')
  <span>{{ auth('vendor')->user()->display() }}</span>
  <form method="post" action="{{ url('/vms/logout') }}">@csrf<button class="linkbtn">{{ __('退出') }}</button></form>
@endsection
@section('body')
<div class="wrap">
  <nav class="side">
    <a href="{{ url('/vms/dashboard') }}" class="{{ request()->is('vms/dashboard') ? 'on' : '' }}">{{ __('概览') }}</a>
    <a href="{{ url('/vms/profile') }}" class="{{ request()->is('vms/profile') ? 'on' : '' }}">{{ __('供应商资料') }}</a>
    <a href="{{ url('/vms/brands') }}" class="{{ request()->is('vms/brands*') ? 'on' : '' }}">{{ __('品牌管理') }}</a>
    <a href="{{ url('/vms/items') }}" class="{{ request()->is('vms/items*') ? 'on' : '' }}">{{ __('商品上架') }}</a>
    <a href="{{ url('/vms/pos') }}" class="{{ request()->is('vms/pos*') ? 'on' : '' }}">{{ __('采购单') }}</a>
  </nav>
  <main class="main">
    @include('layouts.flash')
    @yield('content')
  </main>
</div>
@endsection
