<?php

namespace App\Console\Commands;

use App\Jobs\RunUmallTracking;
use App\Services\UmallTrackingService;
use Illuminate\Console\Command;

class RunUmallTrackingCommand extends Command
{
    protected $signature = 'umall:run {--due : Run only when the random daily trigger time has passed and no scheduled run happened today}';
    protected $description = 'Queue the UM tracking fetch (script1 + script2 + load into umall_tracking)';

    public function handle(UmallTrackingService $svc): int
    {
        if ($this->option('due') && (now()->lt($svc->todayTarget()) || $svc->ranScheduledToday())) {
            return self::SUCCESS;   // not due yet, or already done today
        }
        if ($svc->isRunning()) {
            $this->warn('A run is already in progress; skipped.');

            return self::SUCCESS;
        }
        RunUmallTracking::dispatch($svc->startRun('scheduled'));
        $this->info('UM tracking run queued.');

        return self::SUCCESS;
    }
}
