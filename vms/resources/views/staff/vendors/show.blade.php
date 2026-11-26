@extends('layouts.staff')
@section('title','供应商详情')
@section('content')
@php
$rows = ['申请类型'=>$vendor->application_type==='amend'?'修改已有供应商':'新建供应商','澳大利亚商业号'=>$vendor->abn,'供应商名称'=>$vendor->name,'简称'=>$vendor->short_name,'街道地址'=>$vendor->street_address,'邮寄地址'=>$vendor->postal_address,'邮箱'=>$vendor->email,'电话'=>$vendor->phone,'付款期限(天)'=>$vendor->payment_terms_days,'BSB'=>$vendor->bsb,'银行账号'=>$accountMasked,'金融机构'=>$vendor->bank_institution,'分行名称'=>$vendor->bank_branch,'账户名称'=>$vendor->bank_account_name,'联系人'=>$vendor->contact_name.' '.$vendor->contact_phone,'授权填写人'=>$vendor->auth_name.' '.$vendor->auth_phone.' '.optional($vendor->auth_date)->format('Y-m-d'),'邮箱已验证'=>$vendor->email_verified_at ? $vendor->email_verified_at->format('Y-m-d H:i') : '否','WMS 对应关系'=>$vendor->wms_vendor_ref];
@endphp
<div class="row"><h1>{{ $vendor->display() }} <span class="badge b-{{ $vendor->status }}">{{ $vendor->statusLabel() }}</span></h1>
<span class="right row">
@if(auth('staff')->user()->isAdmin())
  @unless($full)<a class="btn sec" href="{{ url('/vms/staff/vendors/'.$vendor->id.'/reveal') }}">查看完整银行信息(记录审计)</a>@endunless
  <a class="btn sec" href="{{ url('/vms/staff/vendors/'.$vendor->id.'/wms-export') }}">导出 WMS 建档字段</a>
@endif</span></div>
<div class="card"><table>@foreach($rows as $k=>$v)<tr><th style="width:200px">{{ $k }}</th><td>{{ $v }}</td></tr>@endforeach</table></div>

@if($vendor->pending_changes)
<div class="card"><h2>待审核的修改内容</h2><table>
@foreach(collect($vendor->pending_changes)->except(['account_number','auth_confirmed'])->all() as $k=>$v)
<tr><th style="width:200px">{{ $k }}</th><td>{{ $v }}</td><td class="muted">原值:{{ is_scalar($vendor->{$k} ?? null) ? $vendor->{$k} : '' }}</td></tr>@endforeach
@if(isset($vendor->pending_changes['account_number']))<tr><th>银行账号</th><td colspan="2">已提交新账号(加密存储,通过后生效)</td></tr>@endif</table></div>
@endif

@if($vendor->status==='pending' || $vendor->pending_changes)
<div class="card"><h2>审核</h2>
<form method="post" action="{{ url('/vms/staff/vendors/'.$vendor->id.'/approve') }}" class="row">@csrf
<input type="text" name="short_name" placeholder="简称(WMS 建档用)" value="{{ $vendor->short_name }}" style="width:200px">
<input type="text" name="wms_vendor_ref" placeholder="WMS 供应商编号(可稍后回填)" value="{{ $vendor->wms_vendor_ref }}" style="width:260px">
<button class="btn ok">通过</button></form>
<form method="post" action="{{ url('/vms/staff/vendors/'.$vendor->id.'/reject') }}" class="row" style="margin-top:10px">@csrf
<input type="text" name="reason" placeholder="驳回原因(必填)" style="width:420px"><button class="btn bad">驳回</button></form></div>
@elseif($vendor->isApproved())
<div class="card"><h2>WMS 对应关系</h2><form method="post" action="{{ url('/vms/staff/vendors/'.$vendor->id.'/wms-ref') }}" class="row">@csrf
<input type="text" name="short_name" placeholder="简称" value="{{ $vendor->short_name }}" style="width:200px"><input type="text" name="wms_vendor_ref" placeholder="WMS 供应商编号" value="{{ $vendor->wms_vendor_ref }}" style="width:260px"><button class="btn">保存</button></form></div>
@endif
<h2>变更记录</h2>
<table><tr><th>时间</th><th>事件</th><th>说明</th><th>操作人</th></tr>@foreach($vendor->histories as $h)<tr><td>{{ $h->created_at->format('Y-m-d H:i') }}</td><td>{{ $h->event }}</td><td>{{ $h->note }}</td><td>{{ $h->actor }}</td></tr>@endforeach</table>
@endsection
