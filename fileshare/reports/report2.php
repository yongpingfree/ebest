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
    $kw = trim((string) $request->query('kw', ''));
    $like = fn ($s) => '%' . addcslashes($s, '%_\\') . '%';

    // latest load inside the selected date range
    $latestLoad = DB::table('price_comparison')
        ->when($start !== '', fn ($q) => $q->where('load_time', '>=', $start . ' 00:00:00'))
        ->when($end !== '', fn ($q) => $q->where('load_time', '<=', $end . ' 23:59:59'))->max('load_time');

    // a pair (umall sku + ebest sku) that has no entry in the latest load is hidden completely;
    // 4.1 earlier records are hidden when a later load put the same umall product in a different category
    $current = function () use ($latestLoad) {
        return DB::table('price_comparison')->whereExists(function ($q) use ($latestLoad) {
            $q->select(DB::raw(1))->from('price_comparison as l')
                ->whereColumn('l.umall_sku', 'price_comparison.umall_sku')
                ->whereColumn('l.ebest_sku', 'price_comparison.ebest_sku')
                ->where('l.load_time', $latestLoad);
        })->whereNotExists(function ($q) {
            $q->select(DB::raw(1))->from('price_comparison as n')
                ->whereColumn('n.umall_sku', 'price_comparison.umall_sku')
                ->whereColumn('n.load_time', '>', 'price_comparison.load_time')
                ->whereColumn('n.category', '<>', 'price_comparison.category');
        });
    };

    $base = function (bool $withProduct = true) use ($category, $product, $start, $end, $kw, $like, $current) {
        $b = $current();
        if ($category !== '') {
            $b->where('category', $category);
        }
        if ($withProduct && $product !== '') {
            $b->where('umall_sku', $product);
        }
        if ($kw !== '') {
            foreach (preg_split('/\s+/u', $kw) as $w) {   // every keyword must hit one of the titles / skus
                $b->where(fn ($q) => $q->where('umall_title', 'like', $like($w))->orWhere('ebest_title', 'like', $like($w))
                    ->orWhere('umall_sku', 'like', $like($w))->orWhere('ebest_sku', 'like', $like($w)));
            }
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
        $prods = $current()->select('category', 'umall_sku', 'umall_title')->distinct()
            ->orderBy('umall_title')->get();

        return response()->json([
            // categories of the matched pairs plus those that only have unmatched products (latest load)
            'categories' => $current()->distinct()->pluck('category')
                ->merge(DB::table('price_comparison_unmatched')
                    ->where('load_time', DB::table('price_comparison_unmatched')->max('load_time') ?? '0000-00-00 00:00:00')
                    ->whereNotNull('category')->where('category', '<>', '')->distinct()->pluck('category'))
                ->unique()->sort()->values(),
            'products' => $prods,
            'min' => DB::table('price_comparison')->min('load_time'),
            'max' => DB::table('price_comparison')->max('load_time'),
        ]);
    }

    // unmatched products of the latest load inside the selected range (category filter applies; product filter does not)
    $unmatchedBase = function () use ($category, $start, $end, $kw, $like) {
        $q = DB::table('price_comparison_unmatched');
        if ($start !== '') {
            $q->where('load_time', '>=', $start . ' 00:00:00');
        }
        if ($end !== '') {
            $q->where('load_time', '<=', $end . ' 23:59:59');
        }
        $latest = $q->max('load_time');
        $b = DB::table('price_comparison_unmatched')->where('load_time', $latest ?? '0000-00-00 00:00:00');
        if ($category !== '') {
            $b->where('category', $category);
        }
        if ($kw !== '') {
            foreach (preg_split('/\s+/u', $kw) as $w) {
                $b->where(fn ($q) => $q->where('title', 'like', $like($w))->orWhere('sku', 'like', $like($w)));
            }
        }

        return [$b, $latest];
    };

    if ($data === 'unmatched') {
        [$b, $latest] = $unmatchedBase();
        $side = $request->query('side') === 'ebest' ? 'ebest' : 'umall';

        return response()->json(['load_time' => $latest, 'rows' => $b->where('side', $side)->orderBy('category')->orderBy('title')->limit(5000)->get()]);
    }

    // the 4 downloads serve the files generated at the end of the latest comparison run (no query, no filters)
    if ($data === 'export' || $data === 'export_unmatched') {
        $svc = app(\App\Services\PriceComparisonService::class);
        $name = $data === 'export'
            ? ($request->query('higher') === 'umall' ? 'umall_higher' : 'ebest_higher')
            : ($request->query('side') === 'ebest' ? 'unmatched_ebest' : 'unmatched_umall');
        $file = $svc->exportPath($name);
        if (! is_file($file)) {
            return response('文件尚未生成，请先在 UM 页面运行一次对比。', 404);
        }

        return response()->download($file, $name . '_' . date('Ymd_His', filemtime($file)) . '.csv', ['Content-Type' => 'text/csv; charset=utf-8']);
    }

    if ($data === 'report') {
        $rows = $base()->orderByDesc('load_time')->orderBy('umall_title')->get();

        // overall status: latest comparison of each product inside the selected range
        $latest = [];
        foreach ($rows as $r) {                       // rows are newest first
            $latest[$r->category . "\x1f" . $r->umall_sku . "\x1f" . $r->ebest_sku] ??= $r;
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

        [$ub, $ulatest] = $unmatchedBase();
        $uc = $ub->selectRaw('side, count(*) as n')->groupBy('side')->pluck('n', 'side');
        $status['umall_unmatched'] = (int) ($uc['umall'] ?? 0);
        $status['ebest_unmatched'] = (int) ($uc['ebest'] ?? 0);

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
  .stat.click{cursor:pointer;background:#fff7e6;outline:1px solid #ffd591}.stat.click:hover{background:#ffefc2}
  .stat.u{background:#fde8e8}.stat.e{background:#e3f9e5}
  .chartwrap{position:relative;height:340px}
  table{width:100%;border-collapse:collapse;font-size:13px}
  th,td{padding:6px 8px;border-bottom:1px solid #e4e7eb;text-align:left}
  button{padding:8px 14px;border:0;border-radius:6px;background:#1d4ed8;color:#fff;font-size:14px;cursor:pointer}
  th{background:#f0f4f8;position:sticky;top:0}
  .tblwrap{max-height:520px;overflow:auto}
  .cat{min-width:110px;white-space:nowrap}
  .ttl{max-width:240px;word-break:break-word}
  .stat.back{cursor:pointer}
  #back{padding:4px 10px;margin-left:8px;font-size:13px}
  .lo-umall{color:#d92d20;font-weight:600}.lo-ebest{color:#1a7f37;font-weight:600}
  .muted{color:#7b8794;font-size:13px}
</style></head><body><div class="wrap">
<h1>Umall vs eBest 价格对比</h1>
<div class="card"><div class="filters">
  <label>开始日期<input type="date" id="start"></label>
  <label>结束日期<input type="date" id="end"></label>
  <label>类别<select id="cat"></select></label>
  <label>商品<select id="prod"></select></label>
  <label>商品搜索（关键词，空格分隔）<input type="search" id="kw" placeholder="标题 / SKU"></label>
  <button id="search" type="button">搜索</button>
</div><div class="muted" id="range"></div></div>
<div class="card"><div class="stats">
  <div class="stat"><span>对比商品数</span><b id="s_all">-</b></div>
  <div class="stat u"><span>Umall 价格更低</span><b id="s_u">-</b></div>
  <div class="stat e"><span>eBest 价格更低</span><b id="s_e">-</b></div>
  <div class="stat"><span>价格相同</span><b id="s_q">-</b></div>
  <div class="stat click" id="c_um" title="点击在下方表格查看明细"><span>Umall 未匹配商品数</span><b id="s_um">-</b></div>
  <div class="stat click" id="c_eb" title="点击在下方表格查看明细"><span>eBest 未匹配商品数</span><b id="s_eb">-</b></div>
</div><div class="muted">按所选时间范围内每个商品最近一次对比结果统计；在最近一次加载中不存在的商品对（已不再匹配）不显示；类别发生变化的商品，不显示更早、类别不同的历史记录。单价已折算为每 kg / 每 L / 每件</div></div>
<div class="card"><div class="chartwrap"><canvas id="chart"></canvas></div><div class="muted" id="note"></div></div>
<div class="card"><div id="tbltitle" class="muted" style="margin-bottom:6px"></div><div class="tblwrap"><table><thead id="thead"><tr>
  <th>加载时间</th><th class="cat">类别</th><th class="ttl">Umall 商品</th><th>Umall SKU</th><th class="ttl">eBest 商品</th><th>eBest SKU</th>
  <th>售价 Umall/eBest</th><th>Umall 单价</th><th>eBest 单价</th><th>差异 %</th><th>价格更低</th><th>促销说明（未计入比价）</th></tr></thead><tbody id="rows"></tbody></table></div>
  <div style="margin-top:12px;display:flex;gap:10px;flex-wrap:wrap">
    <button id="dl_u" type="button">下载 Umall 价格更高的商品 (CSV)</button>
    <button id="dl_e" type="button">下载 eBest 价格更高的商品 (CSV)</button>
    <button id="dl_uu" type="button">下载 Umall 未匹配商品 (CSV)</button>
    <button id="dl_ue" type="button">下载 eBest 未匹配商品 (CSV)</button>
  </div><div class="muted">按当前筛选条件，每个商品取最近一次对比结果（页面隐藏的记录同样不会导出）；未匹配商品取所选范围内最近一次加载，按类别筛选（不受商品筛选影响）</div></div>
</div>
<script>
const $ = id => document.getElementById(id), KEY = new URLSearchParams(location.search).get('key');
let meta, chart, mode = 'matched';
const MATCHED_HEAD = $('thead').innerHTML;
const esc = s => String(s ?? '').replace(/[&<>"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const qs = o => '?' + new URLSearchParams({key: KEY, ...o});
const promo = x => [x.umall_promo_note && 'Umall：' + esc(x.umall_promo_note), x.ebest_promo_note && 'eBest：' + esc(x.ebest_promo_note)].filter(Boolean).join('<br>');
// 售价：umall/ebest 一个字段；价格更低的一侧加粗并用该侧颜色
const pricePair = x => {
  const f = (v, side) => { const t = esc(v ?? ''); return x.lower_side === side ? `<b class="lo-${side}">${t}</b>` : t; };
  return f(x.umall_price, 'umall') + '/' + f(x.ebest_price, 'ebest');
};
const LOW = {umall: 'Umall', ebest: 'eBest', equal: '相同'};

function fillProducts() {
  const c = $('cat').value;
  $('prod').innerHTML = '<option value="">(All)</option>' + meta.products.filter(p => !c || p.category === c)
    .map(p => `<option value="${esc(p.umall_sku)}">${esc(p.umall_title)}</option>`).join('');
}
async function load() {
  const r = await (await fetch(qs({data: 'report', category: $('cat').value, product: $('prod').value,
    start: $('start').value, end: $('end').value, kw: $('kw').value}))).json();
  $('s_all').textContent = r.status.products; $('s_u').textContent = r.status.umall_lower;
  $('s_e').textContent = r.status.ebest_lower; $('s_q').textContent = r.status.equal;
  $('s_um').textContent = r.status.umall_unmatched; $('s_eb').textContent = r.status.ebest_unmatched;
  $('note').textContent = $('prod').value ? '' : '未选择具体商品时，折线为所有匹配商品单价的平均值';
  if (chart) chart.destroy();
  chart = new Chart($('chart'), {type: 'line', data: {labels: r.chart.map(x => x.t), datasets: [
    {label: 'Umall 单价', data: r.chart.map(x => x.umall), borderColor: '#d92d20', tension: .2},
    {label: 'eBest 单价', data: r.chart.map(x => x.ebest), borderColor: '#1a7f37', tension: .2}]},
    options: {maintainAspectRatio: false, scales: {y: {title: {display: true, text: 'AUD'}}}}});
  if (mode !== 'matched') { return showUnmatched(mode); }
  $('thead').innerHTML = MATCHED_HEAD; $('tbltitle').textContent = '';
  $('rows').innerHTML = r.rows.map(x => `<tr><td>${esc(x.load_time)}</td><td class="cat">${esc(x.category)}</td>
    <td class="ttl">${esc(x.umall_title)}</td><td>${esc(x.umall_sku)}</td><td class="ttl">${esc(x.ebest_title)}</td><td>${esc(x.ebest_sku)}</td>
    <td>${pricePair(x)}</td><td>${x.umall_unit_price} ${esc(x.umall_unit)}</td><td>${x.ebest_unit_price} ${esc(x.ebest_unit)}</td>
    <td>${x.price_diff_pct}</td><td class="lo-${x.lower_side}">${LOW[x.lower_side]}</td>
    <td>${promo(x)}</td></tr>`).join('')
    || '<tr><td colspan="12" class="muted">没有数据</td></tr>';
}
function showMatched() {
  mode = 'matched';
  load().then(() => $('chart').scrollIntoView({behavior: 'smooth', block: 'center'}));
}
async function showUnmatched(side) {
  mode = side;
  const r = await (await fetch(qs({data: 'unmatched', side, category: $('cat').value, start: $('start').value, end: $('end').value, kw: $('kw').value}))).json();
  $('thead').innerHTML = '<tr><th>加载时间</th><th class="cat">类别</th><th class="ttl">商品</th><th>SKU</th><th>售价</th><th>单价</th><th>促销说明（未计入比价）</th></tr>';
  $('tbltitle').innerHTML = (side === 'umall' ? 'Umall' : 'eBest') + ' 未匹配商品（' + r.rows.length + '，最多显示 5000）　<button type="button" id="back">← 返回匹配明细</button>';
  $('back').onclick = showMatched;
  $('rows').innerHTML = r.rows.map(x => `<tr><td>${esc(r.load_time)}</td><td class="cat">${esc(x.category)}</td><td class="ttl">${esc(x.title)}</td>
    <td>${esc(x.sku)}</td><td>${x.price ?? ''}</td><td>${x.unit_price ?? ''} ${esc(x.unit)}</td><td>${esc(x.promo_note)}</td></tr>`).join('') || '<tr><td colspan="7" class="muted">没有数据</td></tr>';
  $('rows').closest('.card').scrollIntoView({behavior: 'smooth'});
}
['s_all', 's_u', 's_e', 's_q'].forEach(i => { const c = $(i).parentElement; c.classList.add('back'); c.title = '点击返回匹配明细'; c.onclick = () => { if (mode !== 'matched') showMatched(); }; });
$('c_um').onclick = () => showUnmatched('umall'); $('c_eb').onclick = () => showUnmatched('ebest');
const dl = side => location.href = qs({data: 'export', higher: side});          // latest generated file, filters not applied
const dlu = side => location.href = qs({data: 'export_unmatched', side});
$('search').onclick = () => load(); $('kw').onkeydown = e => { if (e.key === 'Enter') load(); };
$('dl_uu').onclick = () => dlu('umall'); $('dl_ue').onclick = () => dlu('ebest');
$('dl_u').onclick = () => dl('umall'); $('dl_e').onclick = () => dl('ebest');
(async () => {
  meta = await (await fetch(qs({data: 'meta'}))).json();
  $('cat').innerHTML = '<option value="">(All)</option>' + meta.categories.map(c => `<option>${esc(c)}</option>`).join('');
  $('range').textContent = meta.min ? `可用数据：${meta.min} ~ ${meta.max}` : '暂无数据，请等待每日任务运行';
  fillProducts();
  $('cat').onchange = () => { fillProducts(); load(); };   // keeps the unmatched view if one is open
  ['prod', 'start', 'end'].forEach(i => $(i).onchange = () => { mode = 'matched'; load(); });
  load();
})();
</script></body></html>
HTML, 200)->header('Content-Type', 'text/html; charset=utf-8');
};
