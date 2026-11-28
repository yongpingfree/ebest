@extends('layouts.authbox')
@section('title',__('邮箱验证'))
@section('heading',__('邮箱验证'))
@section('content')
<p>{{ __('验证码已发送至') }} <b>{{ $vendor->email }}</b>,{{ config('vms.verification_ttl_minutes') }} {{ __('分钟内有效。') }}</p>
<form method="post" action="{{ url('/vms/verify') }}">@csrf
  <label>{{ __('6 位验证码') }}</label>
  <input type="text" name="code" inputmode="numeric" maxlength="6" autocomplete="one-time-code" required autofocus>
  <p><button class="btn">{{ __('验证') }}</button></p>
</form>
<form method="post" action="{{ url('/vms/verify/resend') }}" style="margin-top:8px">@csrf
  <button class="btn sec sm">{{ __('没收到?重新发送') }}</button>
</form>
<form method="post" action="{{ url('/vms/logout') }}" style="margin-top:8px">@csrf<button class="btn sec sm">{{ __('退出') }}</button></form>
@endsection
