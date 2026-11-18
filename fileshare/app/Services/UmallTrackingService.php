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

    /** Runs both scripts, then loads the CSV. Returns the number of rows loaded. */
    public function run(): int
    {
        $dir = $this->dir();
        $py = config('fileshare.umall_python');
        $out = storage_path('app/umall');   // writable by the web/queue user
        $raw = $out . '/script1_output';
        $csv = $out . '/umall_items_' . now()->format('dMY') . '.csv';
        File::ensureDirectoryExists($raw, 0775);

        $this->exec([$py, 'script1_fetch.py', $dir . '/productList.md', $raw], $dir, 'script1_fetch.py');
        $this->exec([$py, 'script2_to_csv.py', $raw, $dir . '/categoryMapping.csv', $csv], $dir, 'script2_to_csv.py');

        return $this->loadCsv($csv);
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
