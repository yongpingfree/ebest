@extends('layouts.base')
@section('badge')<span class="badge">运营后台</span>@endsection
@section('userbar')
  <span>{{ auth('staff')->user()->name }}({{ auth('staff')->user()->role }})</span>
  <form method="post" action="{{ url('/vms/staff/logout') }}">@csrf<button class="linkbtn">退出</button></form>
@endsection
@section('body')
<div class="wrap">
  <nav class="side">
    <a href="{{ url('/vms/staff') }}" class="{{ request()->is('vms/staff') ? 'on' : '' }}">概览</a>
    <a href="{{ url('/vms/staff/vendors') }}" class="{{ request()->is('vms/staff/vendors*') ? 'on' : '' }}">供应商审核</a>
    <a href="{{ url('/vms/staff/brands') }}" class="{{ request()->is('vms/staff/brands*') ? 'on' : '' }}">品牌</a>
    <a href="{{ url('/vms/staff/items') }}" class="{{ request()->is('vms/staff/items*') ? 'on' : '' }}">商品</a>
    <a href="{{ url('/vms/staff/pos') }}" class="{{ request()->is('vms/staff/pos*') ? 'on' : '' }}">采购单</a>
  </nav>
  <main class="main">
    @include('layouts.flash')
    @yield('content')
  </main>
</div>
@endsection
