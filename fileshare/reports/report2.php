<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Landing script for /report/2?key=... (umall vs ebest price comparison)
 * - invalid key -> 401 Unauthorized
 * - &data=meta | report&category=..&product=..&start=..&end=.. -> JSON used by the page
 */
return function (Request $request) {
    $expected = (string) config('fileshare.report2_key');
    $key = (string) $request->query('key', '');
    if ($expected === '' || ! hash_equals($expected, $key)) {
        return response('Unauthorized', 401);
    }

    $category = (string) $request->query('category', '');   // '' = All
    $product = (string) $request->query('product', '');    // '' = All (umall sku)
    $start = (string) $request->query('start', '');
    $end = (string) $request->query('end', '');

    $base = function (bool $withProduct = true) use ($category, $product, $start, $end) {
        $b = DB::table('price_comparison');
        if ($category !== '') {
            $b->where('category', $category);
        }
        if ($withProduct && $product !== '') {
            $b->where('umall_sku', $product);
        }
        if ($start !== '') {
            $b->where('load_time', '>=', $start . ' 00:00:00');
        }
        if ($end !== '') {
            $b->where('load_time', '<=', $end . ' 23:59:59');
        }

        return $b;
    };

    $data = $request->query('data');

    if ($data === 'meta') {
        $prods = DB::table('price_comparison')->select('category', 'umall_sku', 'umall_title')->distinct()
            ->orderBy('umall_title')->get();

        return response()->json([
            'categories' => DB::table('price_comparison')->distinct()->orderBy('category')->pluck('category'),
            'products' => $prods,
            'min' => DB::table('price_comparison')->min('load_time'),
            'max' => DB::table('price_comparison')->max('load_time'),
        ]);
    }

    if ($data === 'report' || $data === 'export') {
        $rows = $base()->orderByDesc('load_time')->orderBy('umall_title')->get();

        // overall status: latest comparison of each product inside the selected range
        $latest = [];
        foreach ($rows as $r) {                       // rows are newest first
            $latest[$r->category . "\x1f" . $r->umall_sku . "\x1f" . $r->ebest_sku] ??= $r;
        }
        if ($data === 'export') {
            // products where the chosen side is the more expensive one (latest comparison per product)
            $higher = (string) $request->query('higher', '');          // umall | ebest
            $lowerSide = $higher === 'umall' ? 'ebest' : 'umall';
            return response()->streamDownload(function () use ($latest, $lowerSide) {
                $o = fopen('php://output', 'w');
                fwrite($o, "\xEF\xBB\xBF");
                fputcsv($o, ['common category', 'umall product title', 'umall sku', 'ebest product title', 'ebest sku',
                    'umall unit price', 'umall unit', 'ebest unit price', 'ebest unit', 'price diff pct', 'load time'], ',', '"', '');
                foreach ($latest as $r) {
                    if ($r->lower_side === $lowerSide) {
                        fputcsv($o, [$r->category, $r->umall_title, $r->umall_sku, $r->ebest_title, $r->ebest_sku,
                            $r->umall_unit_price, $r->umall_unit, $r->ebest_unit_price, $r->ebest_unit, $r->price_diff_pct, $r->load_time], ',', '"', '');
                    }
                }
                fclose($o);
            }, ($higher === 'umall' ? 'umall_higher' : 'ebest_higher') . '_' . date('Ymd') . '.csv', ['Content-Type' => 'text/csv; charset=utf-8']);
        }

        $status = ['products' => count($latest), 'umall_lower' => 0, 'ebest_lower' => 0, 'equal' => 0];
        foreach ($latest as $r) {
            $status[$r->lower_side === 'umall' ? 'umall_lower' : ($r->lower_side === 'ebest' ? 'ebest_lower' : 'equal')]++;
        }

        // chart: average unit price per load_time (a single product shows its own price)
        $series = [];
        foreach ($rows as $r) {
            $series[$r->load_time]['u'][] = (float) $r->umall_unit_price;
            $series[$r->load_time]['e'][] = (float) $r->ebest_unit_price;
        }
        ksort($series);
        $avg = fn ($a) => round(array_sum($a) / count($a), 2);
        $chart = [];
        foreach ($series as $t => $v) {
            $chart[] = ['t' => $t, 'umall' => $avg($v['u']), 'ebest' => $avg($v['e'])];
        }

        return response()->json(['status' => $status, 'chart' => $chart, 'rows' => $rows]);
    }

    return response(<<<'HTML'
<!doctype html>
<html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Umall vs eBest 价格对比</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
<style>
  body{font-family:-apple-system,Segoe UI,Helvetica,Arial,sans-serif;margin:0;background:#f4f5f7;color:#1f2933}
  .wrap{max-width:1200px;margin:0 auto;padding:16px}
  h1{font-size:20px;margin:0 0 12px}
  .card{background:#fff;border-radius:8px;padding:14px;margin-bottom:14px;box-shadow:0 1px 2px rgba(0,0,0,.08)}
  .filters{display:flex;flex-wrap:wrap;gap:12px;align-items:flex-end}
  label{display:flex;flex-direction:column;font-size:12px;color:#52606d;gap:4px}
  select,input{padding:6px 8px;border:1px solid #cbd2d9;border-radius:6px;font-size:14px;min-width:150px}
  .stats{display:flex;flex-wrap:wrap;gap:12px}
  .stat{flex:1;min-width:150px;border-radius:8px;padding:12px;background:#f0f4f8}
  .stat b{display:block;font-size:26px}
  .stat.u{background:#e3f9e5}.stat.e{background:#e6f0ff}
  .chartwrap{position:relative;height:340px}
  table{width:100%;border-collapse:collapse;font-size:13px}
  th,td{padding:6px 8px;border-bottom:1px solid #e4e7eb;text-align:left}
  button{padding:8px 14px;border:0;border-radius:6px;background:#1d4ed8;color:#fff;font-size:14px;cursor:pointer}
  th{background:#f0f4f8;position:sticky;top:0}
  .tblwrap{max-height:520px;overflow:auto}
  .lo-umall{color:#1a7f37;font-weight:600}.lo-ebest{color:#1d4ed8;font-weight:600}
  .muted{color:#7b8794;font-size:13px}
</style></head><body><div class="wrap">
<h1>Umall vs eBest 价格对比</h1>
<div class="card"><div class="filters">
  <label>开始日期<input type="date" id="start"></label>
  <label>结束日期<input type="date" id="end"></label>
  <label>类别<select id="cat"></select></label>
  <label>商品<select id="prod"></select></label>
</div><div class="muted" id="range"></div></div>
<div class="card"><div class="stats">
  <div class="stat"><span>对比商品数</span><b id="s_all">-</b></div>
  <div class="stat u"><span>Umall 价格更低</span><b id="s_u">-</b></div>
  <div class="stat e"><span>eBest 价格更低</span><b id="s_e">-</b></div>
  <div class="stat"><span>价格相同</span><b id="s_q">-</b></div>
</div><div class="muted">按所选时间范围内每个商品最近一次对比结果统计，单价已折算为每 kg / 每 L / 每件</div></div>
<div class="card"><div class="chartwrap"><canvas id="chart"></canvas></div><div class="muted" id="note"></div></div>
<div class="card"><div class="tblwrap"><table><thead><tr>
  <th>加载时间</th><th>类别</th><th>Umall 商品</th><th>Umall SKU</th><th>eBest 商品</th><th>eBest SKU</th>
  <th>Umall 单价</th><th>eBest 单价</th><th>差异 %</th><th>价格更低</th></tr></thead><tbody id="rows"></tbody></table></div>
  <div style="margin-top:12px;display:flex;gap:10px;flex-wrap:wrap">
    <button id="dl_u" type="button">下载 Umall 价格更高的商品 (CSV)</button>
    <button id="dl_e" type="button">下载 eBest 价格更高的商品 (CSV)</button>
  </div><div class="muted">按当前筛选条件，每个商品取最近一次对比结果</div></div>
</div>
<script>
const $ = id => document.getElementById(id), KEY = new URLSearchParams(location.search).get('key');
let meta, chart;
const esc = s => String(s ?? '').replace(/[&<>"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const qs = o => '?' + new URLSearchParams({key: KEY, ...o});
const LOW = {umall: 'Umall', ebest: 'eBest', equal: '相同'};

function fillProducts() {
  const c = $('cat').value;
  $('prod').innerHTML = '<option value="">(All)</option>' + meta.products.filter(p => !c || p.category === c)
    .map(p => `<option value="${esc(p.umall_sku)}">${esc(p.umall_title)}</option>`).join('');
}
async function load() {
  const r = await (await fetch(qs({data: 'report', category: $('cat').value, product: $('prod').value,
    start: $('start').value, end: $('end').value}))).json();
  $('s_all').textContent = r.status.products; $('s_u').textContent = r.status.umall_lower;
  $('s_e').textContent = r.status.ebest_lower; $('s_q').textContent = r.status.equal;
  $('note').textContent = $('prod').value ? '' : '未选择具体商品时，折线为所有匹配商品单价的平均值';
  if (chart) chart.destroy();
  chart = new Chart($('chart'), {type: 'line', data: {labels: r.chart.map(x => x.t), datasets: [
    {label: 'Umall 单价', data: r.chart.map(x => x.umall), borderColor: '#1a7f37', tension: .2},
    {label: 'eBest 单价', data: r.chart.map(x => x.ebest), borderColor: '#1d4ed8', tension: .2}]},
    options: {maintainAspectRatio: false, scales: {y: {title: {display: true, text: 'AUD'}}}}});
  $('rows').innerHTML = r.rows.map(x => `<tr><td>${esc(x.load_time)}</td><td>${esc(x.category)}</td>
    <td>${esc(x.umall_title)}</td><td>${esc(x.umall_sku)}</td><td>${esc(x.ebest_title)}</td><td>${esc(x.ebest_sku)}</td>
    <td>${x.umall_unit_price} ${esc(x.umall_unit)}</td><td>${x.ebest_unit_price} ${esc(x.ebest_unit)}</td>
    <td>${x.price_diff_pct}</td><td class="lo-${x.lower_side}">${LOW[x.lower_side]}</td></tr>`).join('')
    || '<tr><td colspan="10" class="muted">没有数据</td></tr>';
}
const dl = side => location.href = qs({data: 'export', higher: side, category: $('cat').value, product: $('prod').value,
  start: $('start').value, end: $('end').value});
$('dl_u').onclick = () => dl('umall'); $('dl_e').onclick = () => dl('ebest');
(async () => {
  meta = await (await fetch(qs({data: 'meta'}))).json();
  $('cat').innerHTML = '<option value="">(All)</option>' + meta.categories.map(c => `<option>${esc(c)}</option>`).join('');
  $('range').textContent = meta.min ? `可用数据：${meta.min} ~ ${meta.max}` : '暂无数据，请等待每日任务运行';
  fillProducts();
  $('cat').onchange = () => { fillProducts(); load(); };
  ['prod', 'start', 'end'].forEach(i => $(i).onchange = load);
  load();
})();
</script></body></html>
HTML, 200)->header('Content-Type', 'text/html; charset=utf-8');
};
