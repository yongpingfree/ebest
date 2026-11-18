<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
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

    /** True once the daily start hour has passed and ebest has not been fetched yet today (scheduled or manual full run). */
    public function isDue(): bool
    {
        return now()->hour >= (int) config('fileshare.compare_start_hour')
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

        $loadTime = now()->toDateTimeString();    // same load_time for matched and unmatched rows
        $this->loadUnmatched($unmatched, $loadTime);

        return $this->loadCsv($csv, $loadTime);
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
