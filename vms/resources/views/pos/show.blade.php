@extends('layouts.vendor')
@section('title',__('采购单详情'))
@section('content')
<div class="row"><h1>{{ $po->draft_no }} <span class="badge b-{{ $po->status }}">{{ $po->statusLabel() }}</span></h1><span class="right row">
@if($po->editableByVendor())<a class="btn" href="{{ url('/vms/pos/'.$po->id.'/edit') }}">{{ __('编辑') }}</a>
<form method="post" action="{{ url('/vms/pos/'.$po->id) }}" onsubmit="return confirm('{{ __('确认删除草稿?') }}')">@csrf @method('DELETE')<button class="btn bad">{{ __('删除') }}</button></form>@endif
<a class="btn sec" href="{{ url('/vms/pos/'.$po->id.'/export') }}">{{ __('导出 xlsx') }}</a></span></div>
@include('pos._summary', ['po'=>$po])
@endsection
