@extends('layouts.authbox')
@section('title','供应商注册')
@section('heading','供应商注册')
@section('content')
<form method="post" action="{{ url('/vms/register') }}">@csrf
  <label>登录邮箱 <span class="req">*</span></label>
  <input type="email" name="email" value="{{ old('email') }}" required autofocus>
  <label>设置密码(至少 10 位) <span class="req">*</span></label>
  <input type="password" name="password" required minlength="10" autocomplete="new-password">
  <label>确认密码 <span class="req">*</span></label>
  <input type="password" name="password_confirmation" required autocomplete="new-password">
  <p class="muted">提交后系统会向该邮箱发送 6 位验证码,验证通过后再填写供应商资料。</p>
  <button class="btn">获取验证码</button>
  <a href="{{ url('/vms/login') }}" class="right">已有账号?登录</a>
</form>
@endsection
