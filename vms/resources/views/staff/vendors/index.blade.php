@extends('layouts.staff')
@section('title','供应商审核')
@section('content')
<h1>供应商</h1>
<form class="filter" method="get"><input type="text" name="q" value="{{ request('q') }}" placeholder="名称 / 邮箱 / ABN">
<select name="status"><option value="">全部</option><option value="pending" @selected(request('status')==='pending')>待审核(新注册和资料修改)</option><option value="amend" @selected(request('status')==='amend')>仅资料修改</option><option value="approved" @selected(request('status')==='approved')>已通过</option><option value="rejected" @selected(request('status')==='rejected')>已驳回</option></select><button class="btn sec">筛选</button></form>
@if(auth('staff')->user()->isAdmin())
<form id="exportForm" method="post" action="{{ url('/vms/staff/vendors/export') }}" class="row" style="margin:8px 0">@csrf
<button class="btn sec" onclick="return document.querySelectorAll('.vsel:checked').length>0 || (alert('请先勾选供应商'), false)">导出所选(CSV,最后一行为 WMS suppliers 建档 SQL)</button>
<label style="font-weight:400"><input type="checkbox" onclick="document.querySelectorAll('.vsel').forEach(c=>c.checked=this.checked)"> 全选本页</label></form>
@endif
<table><tr>@if(auth('staff')->user()->isAdmin())<th></th>@endif<th>供应商名称</th><th>邮箱</th><th>ABN</th><th>状态</th><th>提交时间</th><th>WMS 对应</th><th></th></tr>
@foreach($vendors as $v)@php($newName = $v->pending_changes['name'] ?? null)<tr>@if(auth('staff')->user()->isAdmin())<td><input type="checkbox" class="vsel" name="ids[]" value="{{ $v->id }}" form="exportForm"></td>@endif<td>{{ $v->name ?: '—' }}@if($newName && $newName !== $v->name)<div class="muted">待审核改名为:{{ $newName }}</div>@endif</td><td>{{ $v->email }}</td><td>{{ $v->abn }}</td>
<td><span class="badge b-{{ $v->status }}">{{ $v->statusLabel() }}</span>@if($v->pending_changes) <span class="badge b-pending">有修改待审</span>@endif</td>
<td>{{ optional($v->submitted_at)->format('Y-m-d H:i') }}</td><td>{{ $v->wms_vendor_ref ?: '—' }}</td><td><a href="{{ url('/vms/staff/vendors/'.$v->id) }}">查看</a></td></tr>@endforeach</table>
<div class="pager">{{ $vendors->links() }}</div>
@endsection
