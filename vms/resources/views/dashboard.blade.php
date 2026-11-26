@extends('layouts.vendor')
@section('title','概览')
@section('content')
<h1>欢迎,{{ $vendor->display() }}</h1>
@if(! $vendor->email_verified_at)
  <div class="msg warn">邮箱尚未验证。<a href="{{ url('/vms/verify') }}">去验证</a></div>
@elseif(! $vendor->isApproved())
  <div class="msg warn">供应商资料状态:<b>{{ $vendor->statusLabel() }}</b>。资料审核通过后才能录入商品和创建采购单。<a href="{{ url('/vms/profile') }}">查看/填写资料</a></div>
@endif
<div class="grid">
  @foreach (\App\Models\Item::STATUS as $k => $label)
    <a class="stat" href="{{ url('/vms/items?status='.$k) }}">商品 · {{ $label }}<b>{{ $itemCounts[$k] ?? 0 }}</b></a>
  @endforeach
  @foreach (\App\Models\PurchaseOrder::STATUS as $k => $label)
    <a class="stat" href="{{ url('/vms/pos?status='.$k) }}">采购单 · {{ $label }}<b>{{ $poCounts[$k] ?? 0 }}</b></a>
  @endforeach
</div>
@endsection
