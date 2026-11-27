<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Landing script for /report/1?key=...
 * - invalid key  -> 401 Unauthorized
 * - valid key    -> 'Umall Data Tracking' page (category / product / indicator selectors,
 *                   line chart over time, detail table)
 * - &data=categories | products&category=.. | series&category=..&product=..  -> JSON for the page
 */
return function (Request $request) {
    $expected = (string) config('fileshare.report1_key');
    $key = (string) $request->query('key', '');

    if ($expected === '' || ! hash_equals($expected, $key)) {
        return response('Unauthorized', 401);
    }

    $data = $request->query('data');

    $cats = array_values(array_filter((array) $request->query('category', []), fn ($c) => $c !== '' && $c !== null));
    $q = trim((string) $request->query('q', ''));
    $product = (string) $request->query('product', '');
    $change = (string) $request->query('change', 'all');
    $start = (string) $request->query('start', '');
    $end = (string) $request->query('end', '');

    // base query: category list (empty = all), title search (LIKE), optional exact product, time range
    $base = function (bool $noStart = false, ?string $from = null, bool $noEnd = false) use ($cats, $q, $product, $start, $end) {
        $b = DB::table('umall_tracking');
        if ($cats) {
            $b->whereIn('category', $cats);
        }
        if ($q !== '') {
            $b->where('item_name', 'like', '%' . $q . '%');
        }
        if ($product !== '') {
            $b->where('item_name', $product);
        }
        $startDay = $from ?? $start;
        if ($startDay !== '' && ! $noStart) {
            $b->where('load_time', '>=', $startDay . ' 00:00:00');
        }
        if ($end !== '' && ! $noEnd) {
            $b->where('load_time', '<=', $end . ' 23:59:59');
        }

        return $b;
    };

    // Quantity of every item at the LAST load of the previous day that has data (before $day).
    // Only that one timestamp is used: no older values are carried forward. The range start is ignored on purpose.
    $baselineQty = function (string $day) use ($base) {
        $m = [];
        $pl = $base(true)->where('load_time', '<', $day . ' 00:00:00')->max('load_time');
        if (! $pl) {
            return $m;
        }
        foreach ($base(true)->where('load_time', $pl)->get(['category', 'item_name', 'available_quantity']) as $r) {
            $m[$r->category . "\x1f" . $r->item_name] = $r->available_quantity !== null ? (float) $r->available_quantity : null;
        }

        return $m;
    };

    if ($data === 'latestcsv') {
        $files = glob(storage_path('app/umall') . '/umall_items_*.csv') ?: [];
        usort($files, fn ($a, $b) => filemtime($b) <=> filemtime($a));
        if (! $files) {
            return response('No CSV generated yet.', 404);
        }

        return response()->download($files[0], basename($files[0]), ['Content-Type' => 'text/csv; charset=utf-8']);
    }

    if ($data === 'meta') {
        return response()->json([
            'categories' => DB::table('umall_tracking')->distinct()->orderBy('category')->pluck('category'),
            'min' => DB::table('umall_tracking')->min('load_time'),
            'max' => DB::table('umall_tracking')->max('load_time'),
        ]);
    }

    if ($data === 'products') {
        $b = DB::table('umall_tracking');
        if ($cats) {
            $b->whereIn('category', $cats);
        }

        return response()->json($b->distinct()->orderBy('item_name')->pluck('item_name'));
    }

    // Compare the first load with the last load inside [start, end]
    $compare = function () use ($base, $baselineQty) {
        $loads = $base()->distinct()->orderBy('load_time')->pluck('load_time');
        $res = ['counts' => ['up' => 0, 'down' => 0, 'same' => 0, 'new' => 0, 'missing' => 0, 'stockdown' => 0, 'stockup' => 0], 'rows' => [], 'first' => null, 'last' => null];
        if ($loads->isEmpty()) {
            return $res;
        }
        $first = $loads->first();
        $last = $loads->last();
        $res['first'] = $first;
        $res['last'] = $last;
        $items = [];
        $qty = [];
        foreach ($base()->whereIn('load_time', array_unique([$first, $last]))->get() as $r) {
            $eff = $r->promotion_price_aud !== null ? (float) $r->promotion_price_aud : ($r->price_aud !== null ? (float) $r->price_aud : null);
            $slot = $r->load_time === $last ? 'last' : 'first';
            $items[$r->category . "\x1f" . $r->item_name][$slot] = $eff;
            $qty[$r->category . "\x1f" . $r->item_name][$slot] = $r->available_quantity !== null ? (float) $r->available_quantity : null;
        }
        // old qty = last known qty before the day of the last load (not the previous load: there can be several loads a day)
        $oqty = $baselineQty(substr($last, 0, 10));
        foreach ($items as $k => $v) {
            [$cat, $name] = explode("\x1f", $k, 2);
            $old = $v['first'] ?? null;
            $new = $v['last'] ?? null;
            $hasOld = array_key_exists('first', $v);
            $hasNew = array_key_exists('last', $v);
            if ($first === $last) {
                $status = 'same';
            } elseif ($hasOld && $hasNew) {
                $status = ($old === null || $new === null || abs($new - $old) < 0.005) ? 'same' : ($new > $old ? 'up' : 'down');
            } else {
                $status = $hasNew ? 'new' : 'missing';
            }
            $res['counts'][$status]++;
            $oq = $oqty[$k] ?? null;
            $nq = $qty[$k]['last'] ?? null;
            $stock = 'same';
            if ($oq !== null && $nq !== null) {
                $stock = $nq < $oq ? 'stockdown' : ($nq > $oq ? 'stockup' : 'same');
            }
            if ($stock !== 'same') {
                $res['counts'][$stock]++;
            }
            $res['rows'][] = ['category' => $cat, 'item_name' => $name, 'old_price' => $old, 'new_price' => $new, 'old_qty' => $oq, 'new_qty' => $nq, 'status' => $status, 'stock' => $stock];
        }

        return $res;
    };

    if ($data === 'compare') {
        $res = $compare();
        $res['rows'] = array_values(array_filter($res['rows'], fn ($r) => $change === 'all' || $r['status'] === $change || $r['stock'] === $change));

        return response()->json($res);
    }

    if ($data === 'series') {
        $keep = null;
        if (in_array($change, ['up', 'down', 'same', 'new', 'missing', 'stockdown', 'stockup'], true)) {
            $keep = [];
            foreach ($compare()['rows'] as $r) {
                if ($r['status'] === $change || $r['stock'] === $change) {
                    $keep[$r['category'] . "\x1f" . $r['item_name']] = true;
                }
            }
        }
        // raw per-load series from day $from (default: the selected start)
        $buildSeries = function (?string $from, bool $noEnd = false) use ($base, $keep, $baselineQty) {
            $groups = [];
            foreach ($base(false, $from, $noEnd)->orderBy('load_time')->get(['load_time', 'category', 'item_name', 'price_aud', 'promotion_price_aud', 'available_quantity']) as $r) {
                if ($keep !== null && ! isset($keep[$r->category . "\x1f" . $r->item_name])) {
                    continue;
                }
                $groups[$r->load_time][] = $r;
            }
            $out = [];
            // baseline = quantity at the last load of the previous day (never an earlier load of the same day,
            // never older values carried forward); items missing there have no baseline and count as 0
            $prevDayQty = [];
            $curDayQty = [];
            $curDay = null;
            if ($groups) {
                foreach ($baselineQty(substr((string) array_key_first($groups), 0, 10)) as $k => $v) {
                    if ($keep === null || isset($keep[$k])) {
                        $prevDayQty[$k] = $v;
                    }
                }
            }
            foreach ($groups as $t => $rs) {
                $row = ['load_time' => $t, 'items' => count($rs)];
                // 疑似销量 = old - new quantity when inventory went down, 0 when it went up (summed over the items)
                $sold = null;
                $amount = null;   // 估算销售额 = 疑似销量 x selling price (promotion price when present)
                $curQty = [];
                if ($curDay !== null && $curDay !== substr((string) $t, 0, 10)) {
                    $prevDayQty = $curDayQty;   // day changed: the last load of the previous day is the baseline
                    $curDayQty = [];
                }
                $curDay = substr((string) $t, 0, 10);
                foreach ($rs as $r) {
                    $curQty[$r->category . "\x1f" . $r->item_name] = $r->available_quantity;
                    $o = $prevDayQty[$r->category . "\x1f" . $r->item_name] ?? null;
                    if ($o !== null && $r->available_quantity !== null) {
                        $units = max(0, $o - $r->available_quantity);
                        $price = $r->promotion_price_aud ?? $r->price_aud;
                        $sold = ($sold ?? 0) + $units;
                        if ($price !== null) {
                            $amount = ($amount ?? 0) + $units * (float) $price;
                        }
                    }
                }
                $curDayQty = $curQty;   // replaced, not merged: only the last load of the day counts
                $row['suspected_sales'] = $sold;
                $row['estimated_sales'] = $amount === null ? null : round($amount, 2);
                foreach (['price_aud', 'promotion_price_aud', 'available_quantity'] as $f) {
                    $vals = array_filter(array_map(fn ($r) => $r->$f, $rs), fn ($v) => $v !== null);
                    $row[$f] = $vals ? round(array_sum($vals) / count($vals), 2) : null;
                }
                $out[] = $row;
            }

            return $out;
        };

        // Build ONE series over a fixed window (from the earlier of the selected start and 29 days before the latest
        // load, up to the latest load, ignoring the selected end), smooth it, and only then cut the selected range.
        // A day's value therefore never depends on which start/end dates are picked.
        $latestDay = substr((string) DB::table('umall_tracking')->max('load_time'), 0, 10);
        $winStart = date('Y-m-d', strtotime($latestDay . ' -29 days'));
        if ($start !== '' && $start < $winStart) {
            $winStart = $start;
        }
        $out = $latestDay !== '' ? $buildSeries($winStart, true) : [];

        // 疑似销量 / 估算销售额 more than 6x the typical value (median of the positive points) is an artefact of
        // loading extra categories: replace it with the average of the nearest normal points before and after
        // (only one neighbour -> that value; none -> null)
        foreach (['suspected_sales', 'estimated_sales'] as $fld) {
            $vals = array_column($out, $fld);
            $pos = array_values(array_filter($vals, fn ($v) => $v !== null && $v > 0));
            sort($pos);
            $median = $pos ? (count($pos) % 2 ? $pos[intdiv(count($pos), 2)] : ($pos[count($pos) / 2 - 1] + $pos[count($pos) / 2]) / 2) : 0;
            $isBig = fn ($v) => $median > 0 && $v !== null && $v > 6 * $median;
            $fixed = $vals;
            foreach ($vals as $i => $v) {
                if (! $isBig($v)) {
                    continue;
                }
                $prev = $next = null;
                for ($j = $i - 1; $j >= 0; $j--) {
                    if ($vals[$j] !== null && ! $isBig($vals[$j])) { $prev = $vals[$j]; break; }
                }
                for ($j = $i + 1; $j < count($vals); $j++) {
                    if ($vals[$j] !== null && ! $isBig($vals[$j])) { $next = $vals[$j]; break; }
                }
                $n = array_values(array_filter([$prev, $next], fn ($x) => $x !== null));
                $fixed[$i] = $n ? round(array_sum($n) / count($n), 2) : null;
            }
            foreach ($out as $i => $_) {
                $out[$i][$fld] = $fixed[$i];
            }
        }

        // cut the selected range
        $from = $start !== '' ? $start . ' 00:00:00' : null;
        $to = $end !== '' ? $end . ' 23:59:59' : null;
        $out = array_values(array_filter($out, fn ($r) => ($from === null || $r['load_time'] >= $from) && ($to === null || $r['load_time'] <= $to)));

        return response()->json($out);
    }

    $keyJs = json_encode($key);

    $html = <<<HTML
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Umall Data Tracking</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
<style>
  body{font-family:system-ui,-apple-system,"PingFang SC","Microsoft YaHei",sans-serif;margin:0;padding:16px;background:#f3f6f9;color:#222}
  h1{font-size:1.3rem;margin:0 0 12px}
  .bar{display:flex;gap:12px;flex-wrap:wrap;margin-bottom:12px;align-items:flex-end}
  .box{background:#fff;border-radius:8px;padding:10px 12px;box-shadow:0 1px 3px #0002;flex:1 1 180px}
  .box label{display:block;font-size:.8rem;color:#666;margin-bottom:4px}
  select,input{width:100%;padding:6px;font-size:.95rem;box-sizing:border-box}
  select[multiple]{height:5.5rem}
  button{padding:10px 14px;border:0;border-radius:8px;background:#e6edf3;font-size:.95rem;cursor:pointer}
  .tiles{display:flex;gap:12px;flex-wrap:wrap;margin-bottom:8px}
  .tile{background:#fff;border-radius:8px;padding:10px 14px;box-shadow:0 1px 3px #0002;flex:1 1 140px}
  .tile .n{font-size:1.8rem;font-weight:700}
  .tile[data-c],.pbar div[data-c]{cursor:pointer}
  .tile[data-c]:hover{box-shadow:0 2px 8px #0004}
  .tile.active{outline:2px solid #b5532f}
  .up{color:#b03a2e}.down{color:#1e8449}
  .pbar{display:flex;height:10px;border-radius:5px;overflow:hidden;margin-bottom:16px;background:#ddd}
  .card{background:#fff;border-radius:8px;padding:12px;box-shadow:0 1px 3px #0002;margin-bottom:16px}
  .chartwrap{position:relative;height:340px}
  table{width:100%;border-collapse:collapse;font-size:.9rem}
  th{background:#b5532f;color:#fff;text-align:left;padding:6px}
  td{padding:6px;border-bottom:1px solid #eee}
  .wrap{max-height:420px;overflow:auto}
  .muted{color:#888;font-size:.85rem}
  .hide{display:none}
</style>
</head>
<body>
<h1>Umall Data Tracking</h1>
<div class="bar">
  <div class="box"><label>Start time</label><input type="date" id="start"></div>
  <div class="box"><label>End time</label><input type="date" id="end"></div>
  <div class="box" style="flex:2 1 260px"><label>Title search (contains)</label><input type="search" id="q" placeholder="Part of the product title"></div>
  <div class="box"><label>Change type</label>
    <select id="change">
      <option value="all">All</option><option value="up">Price up</option><option value="down">Price down</option>
      <option value="same">Unchanged</option><option value="stockdown">库存减少</option><option value="stockup">库存增加</option><option value="new" class="nt">New</option><option value="missing" class="nt">Not appearing today</option>
    </select></div>
  <button id="csv">Export CSV (latest)</button>
</div>
<div class="muted" id="cmp" style="margin-bottom:8px"></div>
<div class="tiles">
  <div class="tile" data-c="up" title="Click to list these items below"><div>Price up</div><div class="n up" id="t_up">0</div></div>
  <div class="tile" data-c="down" title="Click to list these items below"><div>Price down</div><div class="n down" id="t_down">0</div></div>
  <div class="tile" data-c="same" title="Click to list these items below"><div>Unchanged</div><div class="n" id="t_same">0</div></div>
  <div class="tile" data-c="stockdown" title="Click to list these items below"><div>库存减少</div><div class="n down" id="t_stockdown">0</div></div>
  <div class="tile" data-c="stockup" title="Click to list these items below"><div>库存增加</div><div class="n up" id="t_stockup">0</div></div>
  <div class="tile nt" data-c="new" title="Click to list these items below"><div>New</div><div class="n" id="t_new">0</div></div>
  <div class="tile nt" data-c="missing" title="Click to list these items below"><div>Not appearing today</div><div class="n" id="t_missing">0</div></div>
</div>
<div class="pbar"><div id="b_down" data-c="down" style="background:#3cb88a"></div><div id="b_same" data-c="same" style="background:#a5b4c3"></div><div id="b_up" data-c="up" style="background:#d9534f"></div><div id="b_new" data-c="new" class="nt" style="background:#f0b866"></div></div>
<div class="bar">
  <div class="box"><label>Category (Ctrl/Cmd-click for several)</label><select id="cat" multiple></select></div>
  <div class="box"><label>Product</label><select id="prod"></select></div>
  <div class="box"><label>Indicator</label>
    <select id="ind">
      <option value="combined" selected>疑似销量和销售额</option>
      <option value="suspected_sales">疑似销量</option>
      <option value="estimated_sales">估算销售额</option>
      <option value="price_aud">price_aud</option>
      <option value="promotion_price_aud">promotion_price_aud</option>
      <option value="available_quantity">available_quantity</option>
    </select></div>
</div>
<div class="card"><div class="chartwrap"><canvas id="chart"></canvas></div><div id="empty" class="muted"></div></div>
<div class="card"><div class="muted" id="tinfo"></div><div class="wrap"><table>
  <thead id="thead"></thead><tbody id="rows"></tbody>
</table></div></div>
<script>
const KEY = $keyJs;
const base = location.pathname;
const \$ = id => document.getElementById(id);
function params(o){
  const p = new URLSearchParams({key: KEY});
  for (const [k, v] of Object.entries(o)) { if (Array.isArray(v)) v.forEach(x => p.append(k + '[]', x)); else if (v !== '' && v != null) p.set(k, v); }
  return base + '?' + p;
}
const get = o => fetch(params(o)).then(r => r.json());
const money = v => v === null || v === undefined || v === '' ? '' : '\$' + Number(v).toLocaleString('en-AU', {minimumFractionDigits: 2, maximumFractionDigits: 2});
const fmt = v => v === null || v === undefined ? '' : v;
const esc = s => String(s).replace(/[&<>"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const selected = sel => Array.from(sel.selectedOptions).map(o => o.value).filter(v => v !== '');   // (All) = empty = no filter
const label = {up:'Price up', down:'Price down', same:'Unchanged', stockdown:'库存减少', stockup:'库存增加', new:'New', missing:'Not appearing today'};
let chart, tableCols = [], tableRows = [], timer, forceCompare = false;

function filters(){
  return {start: \$('start').value, end: \$('end').value, q: \$('q').value.trim(), category: selected(\$('cat')), product: \$('prod').value, change: \$('change').value};
}
function fill(sel, items, allLabel){
  sel.innerHTML = ''; if (allLabel) sel.add(new Option(allLabel, ''));
  items.forEach(v => sel.add(new Option(v, v)));
}
function toggleNT(){
  const on = !\$('prod').value;                     // new / not-appearing only without a specific title
  document.querySelectorAll('.nt').forEach(e => e.classList.toggle('hide', !on));
  if (!on && ['new','missing'].includes(\$('change').value)) \$('change').value = 'all';
}
async function refresh(){
  toggleNT();
  const f = filters();
  const [cmp, series] = await Promise.all([get(Object.assign({data: 'compare'}, f)), get(Object.assign({data: 'series'}, f))]);
  // tiles
  const c = cmp.counts, tot = c.up + c.down + c.same + c.new + c.missing || 1;
  for (const k of Object.keys(c)) \$('t_' + k).textContent = c[k];
  for (const k of ['down','same','up','new']) \$('b_' + k).style.width = (100 * c[k] / tot) + '%';
  \$('cmp').textContent = cmp.first ? 'Comparing load ' + cmp.first + '  ->  ' + cmp.last : 'No data in the selected range.';
  // chart
  const k = \$('ind').value;
  \$('empty').textContent = series.length ? (f.product ? '' : (k === 'combined' ? 'Left axis: sum of 估算销售额 (\$); right axis: sum of 疑似销量 (volume), across the selected items.' : k === 'estimated_sales' ? 'Sum of 估算销售额 (疑似销量 x selling price) across the selected items.' : k === 'suspected_sales' ? 'Sum of the 疑似销量 (qty at the last load of the previous day - current qty, 0 when inventory increased) across the selected items.' : 'Average of the ' + k + ' across the selected items.')) : 'No data.';
  if (chart) chart.destroy();
  const labels = series.map(r => r.load_time);
  const ds = (label, key, color, axis) => ({label, data: series.map(r => r[key]), yAxisID: axis, borderColor: color, backgroundColor: color + '33', tension: .2, spanGaps: true, pointRadius: 3});
  if (k === 'combined') {         // 估算销售额 ($, left axis) and 疑似销量 (volume, right axis) in different colours
    chart = new Chart(\$('chart'), {type: 'line',
      data: {labels, datasets: [ds('估算销售额 (\$)', 'estimated_sales', '#b5532f', 'y'), ds('疑似销量 (volume)', 'suspected_sales', '#2a6fb0', 'y1')]},
      options: {maintainAspectRatio: false, interaction: {mode: 'index', intersect: false}, scales: {
        y: {type: 'linear', position: 'left', beginAtZero: true, title: {display: true, text: '估算销售额 (\$)', color: '#b5532f'}, ticks: {color: '#b5532f', callback: v => '\$' + Number(v).toLocaleString('en-AU')}},
        y1: {type: 'linear', position: 'right', beginAtZero: true, title: {display: true, text: '疑似销量 (volume)', color: '#2a6fb0'}, ticks: {color: '#2a6fb0'}, grid: {drawOnChartArea: false}}},
        plugins: {tooltip: {callbacks: {label: c => c.dataset.label + ': ' + (c.dataset.yAxisID === 'y' ? money(c.parsed.y) : c.parsed.y)}}}}});
  } else {
    const isMoney = k === 'estimated_sales' || k.endsWith('price_aud');
    chart = new Chart(\$('chart'), {type: 'line',
      data: {labels, datasets: [ds(k, k, '#b5532f', 'y')]},
      options: {maintainAspectRatio: false, scales: {y: {beginAtZero: true, ticks: {callback: v => isMoney ? '\$' + Number(v).toLocaleString('en-AU') : v}}},
        plugins: {tooltip: {callbacks: {label: c => c.dataset.label + ': ' + (isMoney ? money(c.parsed.y) : c.parsed.y)}}}}});
  }
  document.querySelectorAll('.tile[data-c]').forEach(t => t.classList.toggle('active', t.dataset.c === f.change));
  // table: time series for a specific product, otherwise (or after a figure was clicked) the comparison list
  if (f.product && !forceCompare) {
    tableCols = ['load_time','category','product','price_aud','promotion_price_aud','available_quantity','疑似销量','估算销售额'];
    const cat = f.category.length === 1 ? f.category[0] : '';
    tableRows = series.slice().reverse().map(r => [r.load_time, cat, f.product, fmt(r.price_aud), fmt(r.promotion_price_aud), fmt(r.available_quantity), fmt(r.suspected_sales), money(r.estimated_sales)]);
    \$('tinfo').textContent = 'Details of the selected product over time';
  } else {
    tableCols = ['category','product','old_price','new_price','old_qty','new_qty','change'];
    const sd = f.change === 'stockdown', su = f.change === 'stockup';
    tableCols.push('疑似销量', '估算销售额'); if (su) tableCols.push('疑似采购量');
    tableRows = cmp.rows.map(r => [r.category, r.item_name, fmt(r.old_price), fmt(r.new_price), fmt(r.old_qty), fmt(r.new_qty), (f.change === 'stockdown' || f.change === 'stockup') ? label[r.stock] : label[r.status] + (r.stock !== 'same' ? ' / ' + label[r.stock] : '')].concat([r.old_qty === null || r.new_qty === null ? '' : Math.max(0, r.old_qty - r.new_qty), r.old_qty === null || r.new_qty === null || r.new_price === null ? '' : money(Math.max(0, r.old_qty - r.new_qty) * r.new_price)], su ? [fmt(r.new_qty - r.old_qty)] : []));
    \$('tinfo').textContent = 'Comparison of the selected items' + (f.change !== 'all' ? ' - ' + label[f.change] : '') + ' (' + tableRows.length + ' rows)';
  }
  \$('thead').innerHTML = '<tr>' + tableCols.map(h => '<th>' + h + '</th>').join('') + '</tr>';
  \$('rows').innerHTML = tableRows.slice(0, 2000).map(r => '<tr>' + r.map(v => '<td>' + esc(v) + '</td>').join('') + '</tr>').join('');
}
async function loadProducts(){
  fill(\$('prod'), await get({data: 'products', category: selected(\$('cat'))}), '(All)');
  refresh();
}
// clicking a comparison figure (tile or bar segment) lists those items in the table below; click again to clear
function pick(c){
  \$('change').value = \$('change').value === c ? 'all' : c;
  forceCompare = \$('change').value !== 'all';
  refresh().then(() => \$('tinfo').scrollIntoView({behavior: 'smooth', block: 'start'}));
}
document.querySelectorAll('[data-c]').forEach(e => e.onclick = () => pick(e.dataset.c));
function debounce(){ clearTimeout(timer); timer = setTimeout(refresh, 300); }
\$('csv').onclick = () => { location.href = params({data: 'latestcsv'}); };   // latest file written by script 2
\$('cat').onchange = () => {
  const cat = \$('cat'), all = cat.options[0];
  if (all.selected && cat.selectedOptions.length > 1) {          // (All) wins when it was just clicked
    if (cat.dataset.hadAll === '1') all.selected = false; else Array.from(cat.options).forEach(o => o.selected = o === all);
  }
  if (!cat.selectedOptions.length) all.selected = true;
  cat.dataset.hadAll = all.selected ? '1' : '0';
  forceCompare = false;
  loadProducts();
};
['prod','ind','start','end'].forEach(id => \$(id).onchange = () => { forceCompare = false; refresh(); });
\$('change').onchange = () => { forceCompare = \$('change').value !== 'all'; refresh(); };
\$('q').oninput = debounce;
(async () => {
  const m = await get({data: 'meta'});
  fill(\$('cat'), m.categories, '(All)');
  \$('cat').options[0].selected = true; \$('cat').dataset.hadAll = '1';
  if (m.min) { \$('start').value = m.min.slice(0, 10); \$('end').value = m.max.slice(0, 10); }
  loadProducts();
})();
</script>
</body>
</html>
HTML;

    return response($html, 200)->header('Content-Type', 'text/html; charset=utf-8');
};
