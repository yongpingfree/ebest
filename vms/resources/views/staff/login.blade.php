@extends('layouts.authbox')
@section('title','运营登录')
@section('heading','eBest 运营后台登录')
@section('content')
<form method="post" action="{{ url('/vms/staff/login') }}">@csrf
  <label>邮箱</label><input type="email" name="email" value="{{ old('email') }}" required autofocus>
  <label>密码</label><input type="password" name="password" required>
  <p><button class="btn">登录</button></p>
</form>
@endsection
