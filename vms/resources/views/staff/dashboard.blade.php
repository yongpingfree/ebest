@extends('layouts.staff')
@section('title','运营概览')
@section('content')
<h1>待处理事项</h1>
<div class="grid">
<a class="stat" href="{{ url('/vms/staff/vendors?status=pending') }}">待审核供应商<b>{{ $vendorsPending }}</b></a>
<a class="stat" href="{{ url('/vms/staff/items?status=submitted') }}">待处理商品(已提交)<b>{{ $itemsSubmitted }}</b></a>
<a class="stat" href="{{ url('/vms/staff/items?status=imported') }}">已导入待上架商品<b>{{ $itemsImported }}</b></a>
<a class="stat" href="{{ url('/vms/staff/pos?status=submitted') }}">待审核采购单<b>{{ $posSubmitted }}</b></a>
<a class="stat" href="{{ url('/vms/staff/pos?status=exception') }}">异常采购单<b>{{ $posException }}</b></a>
</div>
@endsection
