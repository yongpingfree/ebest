@extends('layouts.authbox')
@section('title',__('供应商登录'))
@section('heading',__('供应商登录'))
@section('content')
<form method="post" action="{{ url('/vms/login') }}">@csrf
  <label>{{ __('邮箱') }}</label><input type="email" name="email" value="{{ old('email') }}" required autofocus>
  <label>{{ __('密码') }}</label><input type="password" name="password" required>
  <label style="font-weight:400"><input type="checkbox" name="remember" value="1"> {{ __('记住我') }}</label>
  <p><button class="btn">{{ __('登录') }}</button> <a href="{{ url('/vms/register') }}" class="right">{{ __('新供应商注册') }}</a></p>
</form>
<p class="muted">{{ __('eBest 员工请从') }} <a href="{{ url('/vms/staff/login') }}">{{ __('运营后台') }}</a> {{ __('登录。') }}</p>
@endsection
