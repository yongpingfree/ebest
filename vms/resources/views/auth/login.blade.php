@extends('layouts.authbox')
@section('title','供应商登录')
@section('heading','供应商登录')
@section('content')
<form method="post" action="{{ url('/vms/login') }}">@csrf
  <label>邮箱</label><input type="email" name="email" value="{{ old('email') }}" required autofocus>
  <label>密码</label><input type="password" name="password" required>
  <label style="font-weight:400"><input type="checkbox" name="remember" value="1"> 记住我</label>
  <p><button class="btn">登录</button> <a href="{{ url('/vms/register') }}" class="right">新供应商注册</a></p>
</form>
<p class="muted">eBest 员工请从 <a href="{{ url('/vms/staff/login') }}">运营后台</a> 登录。</p>
@endsection
