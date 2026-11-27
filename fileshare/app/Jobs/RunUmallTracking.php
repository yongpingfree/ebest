<?php

namespace App\Jobs;

use App\Services\UmallTrackingService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;

class RunUmallTracking implements ShouldQueue
{
    use Queueable;

    public int $timeout = 3300;
    public int $tries = 1;

    public function __construct(public int $runId, public bool $fetch = true) {}

    public function handle(UmallTrackingService $svc): void
    {
        $svc->updateRun($this->runId, ['status' => 'running', 'started_at' => now()]);
        try {
            $n = $svc->run($this->fetch);
            $svc->updateRun($this->runId, ['status' => 'done', 'rows' => $n, 'message' => "Loaded $n rows.", 'finished_at' => now()]);
        } catch (\Throwable $e) {
            Log::error('UM tracking failed', ['error' => $e->getMessage()]);
            $svc->updateRun($this->runId, ['status' => 'failed', 'message' => $e->getMessage(), 'finished_at' => now()]);
        }
    }
}
