<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Symfony\Component\Process\Process;

/**
 * Runs script1_fetch.py + script2_to_csv.py and loads the resulting CSV into umall_tracking.
 */
class UmallTrackingService
{
    public function dir(): string
    {
        return rtrim(config('fileshare.umall_dir'), '/');
    }

    /** A run still queued/running after this many minutes is treated as dead. */
    private const STALE_MINUTES = 90;

    public function isRunning(): bool
    {
        return DB::table('umall_tracking_runs')->whereIn('status', ['queued', 'running'])
            ->where('created_at', '>=', now()->subMinutes(self::STALE_MINUTES))->exists();
    }

    /** Today's randomly chosen trigger time: 12:00 +/- up to 1 hour, fixed for the day once picked. */
    public function todayTarget(): \Illuminate\Support\Carbon
    {
        $today = now()->startOfDay();
        $secs = \Illuminate\Support\Facades\Cache::remember(
            'umall_run_offset_' . $today->format('Y-m-d'), now()->addDays(2), fn () => random_int(-3600, 3600)
        );

        return $today->copy()->setTime(12, 0)->addSeconds((int) $secs);
    }

    public function ranScheduledToday(): bool
    {
        return DB::table('umall_tracking_runs')->where('trigger', 'scheduled')
            ->where('created_at', '>=', now()->startOfDay())->exists();
    }

    /** Creates a queued run record; returns its id. */
    public function startRun(string $trigger, ?int $userId = null): int
    {
        return DB::table('umall_tracking_runs')->insertGetId([
            'trigger' => $trigger, 'user_id' => $userId, 'status' => 'queued',
            'created_at' => now(), 'updated_at' => now(),
        ]);
    }

    public function updateRun(int $id, array $data): void
    {
        DB::table('umall_tracking_runs')->where('id', $id)->update($data + ['updated_at' => now()]);
    }

    public function history(int $limit = 30)
    {
        return DB::table('umall_tracking_runs as r')->leftJoin('users as u', 'u.id', '=', 'r.user_id')
            ->orderByDesc('r.id')->limit($limit)
            ->get(['r.*', 'u.name as user_name']);
    }

    /** Runs both scripts, then loads the CSV. Returns the number of rows loaded.
     *  $fetch=false skips script1 and rebuilds from the json already in storage (current mapping applies). */
    public function run(bool $fetch = true): int
    {
        $dir = $this->dir();
        $py = config('fileshare.umall_python');
        $out = storage_path('app/umall');   // writable by the web/queue user
        $raw = $out . '/script1_output';
        $csv = $out . '/umall_items_' . now()->format('dMY') . '.csv';
        File::ensureDirectoryExists($raw, 0775);

        if ($fetch) {
            $this->exec([$py, 'script1_fetch.py', $dir . '/productList.md', $raw], $dir, 'script1_fetch.py');
        } elseif (! glob($raw . '/*.json')) {
            throw new \RuntimeException("No fetched data found in $raw - run 'Umall fetch & load data' first");
        }
        $this->exec([$py, 'script2_to_csv.py', $raw, $dir . '/categoryMapping.csv', $csv], $dir, 'script2_to_csv.py');

        $n = $this->loadCsv($csv);
        $this->remapHistoricalCategories();   // never fails the run

        return $n;
    }

    /** Reads categoryMapping.csv (same format as script2_to_csv.py): keyword/id => category name. */
    public function loadMapping(): array
    {
        $file = $this->dir() . '/categoryMapping.csv';
        $map = [];
        if (! is_file($file)) {
            return $map;
        }
        foreach (preg_split('/\R/u', ltrim((string) file_get_contents($file), "\xEF\xBB\xBF")) as $line) {
            $line = trim($line);
            if ($line === '' || str_starts_with($line, '#')) {
                continue;
            }
            $parts = preg_split('/[,，\t]/u', $line, 2);
            if (count($parts) === 2 && trim($parts[0]) !== '' && trim($parts[1]) !== '') {
                $map[trim($parts[0])] = trim($parts[1]);
            }
        }

        return $map;
    }

    /**
     * Historical rows loaded before a mapping existed keep the raw keyword as category
     * (script2 leaves unmapped categories unchanged). Rewrite those to the mapped name.
     * Returns the number of rows updated.
     */
    public function remapHistoricalCategories(): int
    {
        $updated = 0;
        try {
            foreach ($this->loadMapping() as $key => $name) {
                if ($key !== $name) {
                    $updated += DB::table('umall_tracking')->where('category', $key)->update(['category' => $name]);
                }
            }
        } catch (\Throwable $e) {
            report($e);
        }

        return $updated;
    }

    private function exec(array $cmd, string $cwd, string $name): void
    {
        $p = new Process($cmd, $cwd, null, null, 3000);
        $p->run();
        if (! $p->isSuccessful()) {
            throw new \RuntimeException("$name failed (exit {$p->getExitCode()}): " . trim(substr($p->getErrorOutput() ?: $p->getOutput(), -800)));
        }
    }

    public function loadCsv(string $csv): int
    {
        if (! is_file($csv)) {
            throw new \RuntimeException("CSV not found: $csv");
        }
        $loadTime = now()->toDateTimeString();
        $fh = fopen($csv, 'r');
        $header = fgetcsv($fh, 0, ',', '"', '');
        if ($header) {
            $header[0] = ltrim($header[0], "\xEF\xBB\xBF");   // strip BOM
        }
        $batch = [];
        $n = 0;
        DB::transaction(function () use ($fh, $header, $loadTime, &$batch, &$n) {
            while (($r = fgetcsv($fh, 0, ',', '"', '')) !== false) {
                if (count($r) < count($header)) {
                    continue;
                }
                $row = array_combine($header, array_slice($r, 0, count($header)));
                $batch[] = [
                    'category' => $row['category'],
                    'item_name' => $row['item_name'],
                    'price_aud' => $row['price_aud'] === '' ? null : $row['price_aud'],
                    'promotion_price_aud' => $row['promotion_price_aud'] === '' ? null : $row['promotion_price_aud'],
                    'available_quantity' => $row['available_quantity'] === '' ? null : (int) $row['available_quantity'],
                    'load_time' => $loadTime,
                ];
                $n++;
                if (count($batch) >= 200) {
                    DB::table('umall_tracking')->insert($batch);
                    $batch = [];
                }
            }
            if ($batch) {
                DB::table('umall_tracking')->insert($batch);
            }
        });
        fclose($fh);

        return $n;
    }
}
