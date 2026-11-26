@extends('layouts.base')
@section('body')
<div class="auth">
  <div class="card">
    <h1>@yield('heading')</h1>
    @include('layouts.flash')
    @yield('content')
  </div>
</div>
@endsection
