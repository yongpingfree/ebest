@extends('layouts.vendor')
@section('title', __('品牌管理'))
@section('content')
<h1>{{ __('品牌管理') }}</h1>
@include('brands._manager', ['brands' => $brands])
@endsection
