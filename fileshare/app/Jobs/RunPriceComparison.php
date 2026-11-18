<?php

namespace App\Jobs;

use App\Services\PriceComparisonService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;

class RunPriceComparison implements ShouldQueue
{
    use Queueable;

    public int $timeout = 3300;
    public int $tries = 1;

    public function __construct(public int $runId, public bool $fetchEbest = true) {}

    public function handle(PriceComparisonService $svc): void
    {
        $svc->updateRun($this->runId, ['status' => 'running', 'started_at' => now()]);
        try {
            $n = $svc->run($this->fetchEbest);
            $svc->updateRun($this->runId, ['status' => 'done', 'rows' => $n, 'message' => "Loaded $n rows ({$svc->ebestNote}).", 'finished_at' => now()]);
        } catch (\Throwable $e) {
            Log::error('Price comparison failed', ['error' => $e->getMessage()]);
            $svc->updateRun($this->runId, ['status' => 'failed', 'message' => $e->getMessage(), 'finished_at' => now()]);
        }
    }
}
