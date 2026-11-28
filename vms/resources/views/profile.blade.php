@extends('layouts.vendor')
@section('title',__('供应商资料'))
@section('content')
<h1>{{ __('供应商注册资料') }} <span class="badge b-{{ $vendor->status }}">{{ $vendor->statusLabel() }}</span></h1>
@if($vendor->status==='rejected' || ($vendor->isApproved() && $vendor->reject_reason))
  <div class="msg err">{{ __('审核未通过:') }}{{ $vendor->reject_reason }}{{ __('。请修改后重新提交。') }}</div>
@endif
@if($vendor->isApproved() && $vendor->pending_changes)
  <div class="msg warn">{{ __('资料修改申请已提交,正在审核。审核通过前仍使用原资料。') }}</div>
@endif
@php
$locked = $vendor->status==='pending' || ($vendor->isApproved() && $vendor->pending_changes);
@endphp
@php
$p = $vendor->pending_changes ?: [];
@endphp
@php
$g = fn($k,$d=null) => old($k, $p[$k] ?? $vendor->{$k} ?? $d);
@endphp
<form method="post" action="{{ url('/vms/profile') }}">@csrf
<fieldset @disabled($locked) style="border:0;padding:0;margin:0">
<div class="card">
  <h2>{{ __('申请类型') }}</h2>
  <select name="application_type">
    <option value="new" @selected($g('application_type','new')==='new')>{{ __('新建供应商') }}</option>
    <option value="amend" @selected($g('application_type')==='amend')>{{ __('修改已有供应商') }}</option>
  </select>
  <h2>{{ __('供应商信息') }}</h2>
  <div class="cols">
    <div><label>{{ __('澳大利亚商业号 ABN(11 位数字)') }}<span class="req">*</span></label><input type="text" name="abn" value="{{ $g('abn') }}" maxlength="14"></div>
    <div><label>{{ __('供应商名称(发票上的正式名称)') }}<span class="req">*</span></label><input type="text" name="name" value="{{ $g('name') }}"></div>
    <div><label>{{ __('街道地址') }}<span class="req">*</span></label><input type="text" name="street_address" value="{{ $g('street_address') }}"></div>
    <div><label>{{ __('邮寄地址') }}<span class="req">*</span></label><input type="text" name="postal_address" value="{{ $g('postal_address') }}"></div>
    <div><label>{{ __('电话') }}<span class="req">*</span></label><input type="text" name="phone" value="{{ $g('phone') }}"></div>
    <div><label>{{ __('付款期限(天)') }}<span class="req">*</span></label><input type="number" name="payment_terms_days" value="{{ $g('payment_terms_days') }}" min="0"></div>
    <div><label>{{ __('电子邮箱') }}</label><input type="text" value="{{ $vendor->email }}" disabled></div>
  </div>
  <h2>{{ __('银行信息(澳大利亚)') }}</h2>
  <p class="muted">{{ __('银行信息属敏感数据,加密存储,仅 eBest 管理员可查看完整内容。') }}</p>
  <div class="cols">
    <div><label>BSB<span class="req">*</span></label><input type="text" name="bsb" value="{{ $g('bsb') }}" placeholder="082-001"></div>
    <div><label>{{ __('账号') }}<span class="req">*</span> @if($maskedAccount)<span class="muted">{{ __('(已保存') }} {{ $maskedAccount }}{{ __(',留空表示不修改)') }}</span>@endif</label><input type="text" name="account_number" value="" autocomplete="off"></div>
    <div><label>{{ __('金融机构') }}<span class="req">*</span></label><input type="text" name="bank_institution" value="{{ $g('bank_institution') }}"></div>
    <div><label>{{ __('分行名称') }}<span class="req">*</span></label><input type="text" name="bank_branch" value="{{ $g('bank_branch') }}"></div>
    <div><label>{{ __('账户名称(应与供应商名称一致)') }}<span class="req">*</span></label><input type="text" name="bank_account_name" value="{{ $g('bank_account_name') }}"></div>
  </div>
  <h2>{{ __('联系人') }}</h2>
  <div class="cols">
    <div><label>{{ __('联系人姓名') }}<span class="req">*</span></label><input type="text" name="contact_name" value="{{ $g('contact_name') }}"></div>
    <div><label>{{ __('联系人电话') }}<span class="req">*</span></label><input type="text" name="contact_phone" value="{{ $g('contact_phone') }}"></div>
  </div>
  <h2>{{ __('授权声明') }}</h2>
  <label style="font-weight:400"><input type="checkbox" name="auth_confirmed" value="1" @checked(old('auth_confirmed', $vendor->auth_confirmed))> {{ __('本人已获供应商授权提供以上信息。') }}</label>
  <div class="cols">
    <div><label>{{ __('填写人姓名') }}<span class="req">*</span></label><input type="text" name="auth_name" value="{{ $g('auth_name') }}"></div>
    <div><label>{{ __('填写人电话') }}<span class="req">*</span></label><input type="text" name="auth_phone" value="{{ $g('auth_phone') }}"></div>
  </div>
  <p class="muted">{{ __('提交日期将自动记录为今天;电子确认代替手写签名。') }}</p>
  @unless($locked)<p><button class="btn">{{ __('提交审核') }}</button></p>@endunless
</div>
</fieldset>
</form>
@include('brands._manager', ['brands' => $vendor->brands])
@if($vendor->wms_vendor_ref)<p class="muted">{{ __('eBest 档案编号:') }}{{ $vendor->wms_vendor_ref }}</p>@endif
<h2>{{ __('资料变更记录') }}</h2>
<table><tr><th>{{ __('时间') }}</th><th>{{ __('事件') }}</th><th>{{ __('说明') }}</th></tr>
@foreach($vendor->histories as $h)<tr><td>{{ $h->created_at->format('Y-m-d H:i') }}</td><td>{{ __($h->event) }}</td><td>{{ __($h->note) }}</td></tr>@endforeach
</table>
@endsection
