@extends('layouts.staff')
@section('title','供应商审核')
@section('content')
<h1>供应商</h1>
<form class="filter" method="get"><input type="text" name="q" value="{{ request('q') }}" placeholder="名称 / 邮箱 / ABN">
<select name="status"><option value="">全部</option><option value="pending" @selected(request('status')==='pending')>待审核</option><option value="amend" @selected(request('status')==='amend')>待审核的修改</option><option value="approved" @selected(request('status')==='approved')>已通过</option><option value="rejected" @selected(request('status')==='rejected')>已驳回</option></select><button class="btn sec">筛选</button></form>
<table><tr><th>供应商名称</th><th>邮箱</th><th>ABN</th><th>状态</th><th>提交时间</th><th>WMS 对应</th><th></th></tr>
@foreach($vendors as $v)<tr><td>{{ $v->name ?: '—' }}</td><td>{{ $v->email }}</td><td>{{ $v->abn }}</td>
<td><span class="badge b-{{ $v->status }}">{{ $v->statusLabel() }}</span>@if($v->pending_changes) <span class="badge b-pending">有修改待审</span>@endif</td>
<td>{{ optional($v->submitted_at)->format('Y-m-d H:i') }}</td><td>{{ $v->wms_vendor_ref ?: '—' }}</td><td><a href="{{ url('/vms/staff/vendors/'.$v->id) }}">查看</a></td></tr>@endforeach</table>
<div class="pager">{{ $vendors->links() }}</div>
@endsection
