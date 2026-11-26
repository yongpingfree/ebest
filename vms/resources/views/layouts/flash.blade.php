@if (session('status'))<div class="msg ok">{{ session('status') }}</div>@endif
@if (session('warning'))<div class="msg warn">{{ session('warning') }}</div>@endif
@if ($errors->any())
<div class="msg err">请修正以下问题:<ul>
@foreach ($errors->all() as $e)
  @if (is_array($e)) @foreach ($e as $x)<li>{{ $x }}</li>@endforeach @else <li>{{ $e }}</li> @endif
@endforeach
</ul></div>
@endif
