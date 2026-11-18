<?php

namespace App\Console\Commands;

use App\Jobs\RunPriceComparison;
use App\Services\PriceComparisonService;
use Illuminate\Console\Command;

class RunPriceComparisonCommand extends Command
{
    protected $signature = 'compare:run {--due : Run only after the daily start hour and when no scheduled run happened today} {--no-fetch : Re-compare with the ebest data already downloaded (no ebest fetch)}';
    protected $description = 'Queue the umall vs ebest price comparison (fetch ebest, match, load into price_comparison)';

    public function handle(PriceComparisonService $svc): int
    {
        if ($this->option('due') && ! $svc->isDue()) {
            return self::SUCCESS;
        }
        if ($svc->isRunning()) {
            $this->warn('A run is already in progress; skipped.');

            return self::SUCCESS;
        }
        $noFetch = (bool) $this->option('no-fetch');
        RunPriceComparison::dispatch($svc->startRun($this->option('due') ? 'scheduled' : ($noFetch ? 'manual (no fetch)' : 'manual')), ! $noFetch);
        $this->info('Price comparison run queued.');

        return self::SUCCESS;
    }
}
