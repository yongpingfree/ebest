<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Http;
use Symfony\Component\Process\Process;

/**
 * Daily job: fetch ebest items (api/fetch_all_items.py), match against the umall json files already on
 * disk (match_products.py) and load the result into price_comparison with a load_time.
 */
class PriceComparisonService
{
    private const STALE_MINUTES = 90;

    public function dir(): string
    {
        return rtrim(config('fileshare.compare_dir'), '/');
    }

    public function isRunning(): bool
    {
        return DB::table('price_comparison_runs')->whereIn('status', ['queued', 'running'])
            ->where('created_at', '>=', now()->subMinutes(self::STALE_MINUTES))->exists();
    }

    /** Daily start time as minutes after midnight (COMPARE_START_HOUR + COMPARE_START_MINUTE). */
    public function startMinuteOfDay(): int
    {
        return (int) config('fileshare.compare_start_hour') * 60 + (int) config('fileshare.compare_start_minute');
    }

    /** True once the daily start hour has passed and ebest has not been fetched yet today (scheduled or manual full run). */
    public function isDue(): bool
    {
        return $this->startMinuteOfDay() <= now()->hour * 60 + now()->minute
            && ! DB::table('price_comparison_runs')->whereIn('trigger', ['scheduled', 'manual'])   // runs that fetch ebest
                ->where('created_at', '>=', now()->startOfDay())->exists();   // 'manual (no fetch)' does not count
    }

    public function startRun(string $trigger, ?int $userId = null): int
    {
        return DB::table('price_comparison_runs')->insertGetId([
            'trigger' => $trigger, 'user_id' => $userId, 'status' => 'queued', 'created_at' => now(), 'updated_at' => now(),
        ]);
    }

    public function history(int $limit = 15)
    {
        return DB::table('price_comparison_runs as r')->leftJoin('users as u', 'u.id', '=', 'r.user_id')
            ->orderByDesc('r.id')->limit($limit)->get(['r.*', 'u.name as user_name']);
    }

    public function updateRun(int $id, array $data): void
    {
        DB::table('price_comparison_runs')->where('id', $id)->update($data + ['updated_at' => now()]);
    }

    /** @param bool $fetchEbest false = re-compare using the ebest file from the last fetch (no download) */
    /** Human-readable note about where the ebest data came from (shown in the run history). */
    public string $ebestNote = '';

    public function run(bool $fetchEbest = true): int
    {
        $dir = $this->dir();
        $py = config('fileshare.umall_python');
        $umall = config('fileshare.compare_umall_dir');
        $work = storage_path('app/compare');
        File::ensureDirectoryExists($work, 0775);
        $ebest = $work . '/ebest_items.json';
        $csv = $work . '/matches_' . now()->format('Ymd_His') . '.csv';
        $unmatched = $work . '/unmatched_' . now()->format('Ymd_His') . '.csv';

        if (! glob($umall . '/*.json')) {
            throw new \RuntimeException("No umall json files found in $umall - run the UM tracking fetch first (this job never fetches umall)");
        }
        if ($fetchEbest) {
            $this->exec([$py, $dir . '/fetch_all_items.py', $ebest . '.tmp'], $dir, 'fetch_all_items.py');
            rename($ebest . '.tmp', $ebest);
            $this->ebestNote = 'ebest fetched now';
        } elseif (! is_file($ebest)) {
            throw new \RuntimeException('No ebest data downloaded yet - run the full comparison (with ebest fetch) first');
        }
        if (! $fetchEbest) {
            $this->ebestNote = 'ebest NOT fetched, reused file from ' . date('Y-m-d H:i', filemtime($ebest));
        }
        $this->exec([$py, $dir . '/match_products.py', '--umall-dir', $umall, '--ebest', $ebest,
            '--rules', $dir . '/matching_rules.json', '--out', $csv, '--extended', '--unmatched-out', $unmatched], $dir, 'match_products.py');

        $this->refreshFreeShipping();             // never fails the comparison
        $loadTime = now()->toDateTimeString();    // same load_time for matched and unmatched rows
        $this->loadUnmatched($unmatched, $loadTime);
        $n = $this->loadCsv($csv, $loadTime);
        $this->exportLatestFiles($loadTime);      // the 4 download files of the report page

        return $n;
    }

    public function freeShippingPath(): string
    {
        return storage_path('app/compare/free_shipping.json');
    }

    /** Minimum non-zero 'amount' of umall's getPinkageList (free-shipping threshold); keeps the previous value on failure. */
    public function refreshFreeShipping(): ?float
    {
        $token = (string) config('fileshare.umall_api_token');
        if ($token === '') {
            return null;
        }
        try {
            $res = Http::timeout(30)->withHeaders([
                'accept' => '*/*', 'authorization' => 'Bearer ' . $token, 'origin' => 'https://m.umall.com.au',
                'platform' => 'wap', 'ulang' => 'zh',
                'user-agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/156.0.0.0 Safari/537.36',
            ])->get(config('fileshare.umall_pinkage_url'), ['company_id' => 1]);
            $amounts = [];
            $json = $res->json() ?? [];
            array_walk_recursive($json, function ($v, $k) use (&$amounts) {
                if ($k === 'amount' && is_numeric($v) && (float) $v > 0) {
                    $amounts[] = (float) $v;
                }
            });
            if (! $res->successful() || ! $amounts) {
                return null;
            }
            $min = min($amounts);
            File::ensureDirectoryExists(dirname($this->freeShippingPath()), 0775);
            $this->buildFreeDeliveryCsv($res->body());   // never fails the threshold lookup
            file_put_contents($this->freeShippingPath(), json_encode(['amount' => $min, 'updated_at' => now()->toDateTimeString()]));

            return $min;
        } catch (\Throwable $e) {
            report($e);

            return null;
        }
    }

    public function freeDeliveryCsvPath(): string
    {
        return storage_path('app/compare/umallfreedelivery.csv');
    }

    /** Convert the raw getPinkageList response into umallfreedelivery.csv (free_delivery_to_csv.py); the old file is kept on failure. */
    private function buildFreeDeliveryCsv(string $rawJson): void
    {
        try {
            $json = storage_path('app/compare/umallfreedelivery.json');
            $tmp = storage_path('app/compare/umallfreedelivery.tmp.csv');
            file_put_contents($json, $rawJson);
            $this->exec([config('fileshare.umall_python'), $this->dir() . '/free_delivery_to_csv.py', $json, '-o', $tmp],
                $this->dir(), 'free_delivery_to_csv.py');
            rename($tmp, $this->freeDeliveryCsvPath());
        } catch (\Throwable $e) {
            report($e);
        }
    }

    public function freeShippingText(): string
    {
        $d = is_file($this->freeShippingPath()) ? json_decode(file_get_contents($this->freeShippingPath()), true) : null;

        return $d ? 'Umall消费满$' . rtrim(rtrim(number_format($d['amount'], 2, '.', ''), '0'), '.') . '免运费 (更新于' . substr($d['updated_at'], 0, 10) . ')' : '';
    }

    /** The four files the report page downloads (generated at the end of every comparison run). */
    public const EXPORT_FILES = ['umall_higher', 'ebest_higher', 'unmatched_umall', 'unmatched_ebest'];

    public function exportPath(string $name): string
    {
        return storage_path('app/compare/latest/' . $name . '.csv');
    }

    /** Write the 4 download files from the comparison just loaded ($loadTime); files are replaced atomically. */
    public function exportLatestFiles(string $loadTime): void
    {
        File::ensureDirectoryExists(dirname($this->exportPath('x')), 0775);
        $head = ['common category', 'umall product title', 'umall sku', 'ebest product title', 'ebest sku',
            'umall/ebest selling price', 'umall selling price', 'ebest selling price', 'umall unit price', 'umall unit',
            'ebest unit price', 'ebest unit', 'price diff pct', 'umall promo note', 'ebest promo note', 'load time'];
        foreach (['umall', 'ebest'] as $higher) {          // files list products where this side is the more expensive one
            $lower = $higher === 'umall' ? 'ebest' : 'umall';
            $q = DB::table('price_comparison')->where('load_time', $loadTime)->where('lower_side', $lower)
                ->orderBy('category')->orderBy('umall_title');
            $this->writeCsv($this->exportPath($higher . '_higher'), $head, $q, fn ($r) => [
                $r->category, $r->umall_title, $r->umall_sku, $r->ebest_title, $r->ebest_sku,
                ($r->umall_price ?? '') . '/' . ($r->ebest_price ?? ''), $r->umall_price, $r->ebest_price,
                $r->umall_unit_price, $r->umall_unit, $r->ebest_unit_price, $r->ebest_unit, $r->price_diff_pct,
                $r->umall_promo_note, $r->ebest_promo_note, $r->load_time]);
        }
        foreach (['umall', 'ebest'] as $side) {
            $q = DB::table('price_comparison_unmatched')->where('load_time', $loadTime)->where('side', $side)
                ->orderBy('category')->orderBy('title');
            $this->writeCsv($this->exportPath('unmatched_' . $side),
                ['common category', 'product title', 'sku', 'selling price', 'unit price', 'unit', 'promo note', 'load time'], $q,
                fn ($x) => [$x->category, $x->title, $x->sku, $x->price, $x->unit_price, $x->unit, $x->promo_note, $x->load_time]);
        }
    }

    private function writeCsv(string $path, array $header, $query, callable $map): void
    {
        $tmp = $path . '.tmp';
        $o = fopen($tmp, 'w');
        fwrite($o, "\xEF\xBB\xBF");
        fputcsv($o, $header, ',', '"', '');
        foreach ($query->cursor() as $r) {
            fputcsv($o, $map($r), ',', '"', '');
        }
        fclose($o);
        rename($tmp, $path);
    }

    private function exec(array $cmd, string $cwd, string $name): void
    {
        $p = new Process($cmd, $cwd, null, null, 3000);
        $p->run();
        if (! $p->isSuccessful()) {
            throw new \RuntimeException("$name failed (exit {$p->getExitCode()}): " . trim(substr($p->getErrorOutput() ?: $p->getOutput(), -800)));
        }
    }

    public function loadUnmatched(string $csv, string $loadTime): int
    {
        $fh = fopen($csv, 'r');
        $header = fgetcsv($fh, 0, ',', '"', '');
        $header[0] = ltrim($header[0], "\xEF\xBB\xBF");
        $n = 0;
        $batch = [];
        DB::transaction(function () use ($fh, $header, $loadTime, &$batch, &$n) {
            while (($r = fgetcsv($fh, 0, ',', '"', '')) !== false) {
                if (count($r) < count($header)) {
                    continue;
                }
                $row = array_combine($header, array_slice($r, 0, count($header)));
                $batch[] = [
                    'side' => $row['side'], 'category' => $row['common category'],
                    'title' => mb_substr($row['product title'], 0, 500), 'sku' => $row['sku'],
                    'unit_price' => $row['unit price'] === '' ? null : $row['unit price'], 'unit' => $row['unit'],
                    'promo_note' => mb_substr($row['promo note'] ?? '', 0, 500) ?: null,
                    'price' => ($row['selling price'] ?? '') === '' ? null : $row['selling price'],
                    'load_time' => $loadTime,
                ];
                $n++;
                if (count($batch) >= 500) {
                    DB::table('price_comparison_unmatched')->insert($batch);
                    $batch = [];
                }
            }
            if ($batch) {
                DB::table('price_comparison_unmatched')->insert($batch);
            }
        });
        fclose($fh);

        return $n;
    }

    public function loadCsv(string $csv, ?string $loadTime = null): int
    {
        $loadTime ??= now()->toDateTimeString();
        $fh = fopen($csv, 'r');
        $header = fgetcsv($fh, 0, ',', '"', '');
        $header[0] = ltrim($header[0], "\xEF\xBB\xBF");
        $n = 0;
        $batch = [];
        DB::transaction(function () use ($fh, $header, $loadTime, &$batch, &$n) {
            while (($r = fgetcsv($fh, 0, ',', '"', '')) !== false) {
                if (count($r) < count($header)) {
                    continue;
                }
                $row = array_combine($header, array_slice($r, 0, count($header)));
                $u = (float) $row['umall unit price'];
                $e = (float) $row['ebest unit price'];
                $batch[] = [
                    'category' => $row['common category'],
                    'umall_title' => $row['umall product title'], 'umall_sku' => $row['umall sku'],
                    'ebest_title' => $row['ebest product title'], 'ebest_sku' => $row['ebest sku'],
                    'umall_unit_price' => $u, 'umall_unit' => $row['umall unit'],
                    'ebest_unit_price' => $e, 'ebest_unit' => $row['ebest unit'],
                    'price_diff_pct' => $row['price diff pct'],
                    'umall_price' => ($row['umall price (AUD)'] ?? '') === '' ? null : $row['umall price (AUD)'],
                    'ebest_price' => ($row['ebest price (AUD)'] ?? '') === '' ? null : $row['ebest price (AUD)'],
                    'umall_promo_note' => mb_substr($row['umall promo note'] ?? '', 0, 500) ?: null,
                    'ebest_promo_note' => mb_substr($row['ebest promo note'] ?? '', 0, 500) ?: null,
                    'lower_side' => abs($u - $e) < 0.005 ? 'equal' : ($u < $e ? 'umall' : 'ebest'),
                    'load_time' => $loadTime,
                ];
                $n++;
                if (count($batch) >= 200) {
                    DB::table('price_comparison')->insert($batch);
                    $batch = [];
                }
            }
            if ($batch) {
                DB::table('price_comparison')->insert($batch);
            }
        });
        fclose($fh);

        return $n;
    }
}
