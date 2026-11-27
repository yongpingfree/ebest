<?php

namespace App\Filament\Pages;

use App\Jobs\RunPriceComparison;
use App\Jobs\RunUmallTracking;
use App\Services\PriceComparisonService;
use App\Services\UmallTrackingService;
use App\Support\Permissions;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Illuminate\Support\Facades\DB;

class UmallTracking extends Page
{
    protected string $view = 'filament.pages.umall-tracking';

    protected static ?string $navigationLabel = 'UM tracking';
    protected static ?string $title = 'UM tracking';
    protected static ?int $navigationSort = 3;

    public static function canAccess(): bool
    {
        return auth()->user()?->isAdmin() ?? false;
    }

    /** The fetch button needs the 'UM' permission (see the user's Permissions list). */
    public function canRun(): bool
    {
        return auth()->user()?->hasPermission(Permissions::UM) ?? false;
    }

    public function run(): void
    {
        $this->startTracking(true);
    }

    /** Reloads from the json already in storage (no API fetch); category mapping is re-applied. */
    public function loadOnly(): void
    {
        $this->startTracking(false);
    }

    private function startTracking(bool $fetch): void
    {
        if (! $this->canRun()) {
            Notification::make()->title("The 'UM' permission is required")->danger()->send();

            return;
        }
        $svc = app(UmallTrackingService::class);
        if ($svc->isRunning()) {
            Notification::make()->title('Already running')->warning()->send();

            return;
        }
        RunUmallTracking::dispatch($svc->startRun($fetch ? 'manual' : 'manual (load only)', auth()->id()), $fetch);
        Notification::make()->title($fetch ? 'Fetch started' : 'Load started')->body('Runs in the background; see the run history below.')->success()->send();
    }

    /** Manually triggers the daily comparison job (ebest fetch + match + load); never fetches umall. */
    public function runComparison(): void
    {
        $this->startComparison(true);
    }

    /** Re-runs the matching and load using the ebest data from the last fetch; nothing is downloaded. */
    public function recompare(): void
    {
        $this->startComparison(false);
    }

    private function startComparison(bool $fetchEbest): void
    {
        if (! $this->canRun()) {
            Notification::make()->title("The 'UM' permission is required")->danger()->send();

            return;
        }
        $svc = app(PriceComparisonService::class);
        if ($svc->isRunning()) {
            Notification::make()->title('Comparison already running')->warning()->send();

            return;
        }
        RunPriceComparison::dispatch($svc->startRun($fetchEbest ? 'manual' : 'manual (no fetch)', auth()->id()), $fetchEbest);
        Notification::make()->title($fetchEbest ? 'Comparison started' : 'Re-comparison started')->body('Runs in the background; see the comparison history below.')->success()->send();
    }

    public function getInfo(): array
    {
        $last = DB::table('umall_tracking')->max('load_time');
        $svc = app(UmallTrackingService::class);

        return [
            'last_load' => $last,
            'last_rows' => $last ? DB::table('umall_tracking')->where('load_time', $last)->count() : 0,
            'total_rows' => DB::table('umall_tracking')->count(),
            'running' => $svc->isRunning(),
            'next_run' => $svc->ranScheduledToday()
                ? 'Tomorrow, between 11:00 and 13:00'
                : 'Today at about ' . $svc->todayTarget()->format('H:i') . ' (random time between 11:00 and 13:00)',
            'history' => $svc->history(),
            'cmp_running' => app(PriceComparisonService::class)->isRunning(),
            'cmp_history' => app(PriceComparisonService::class)->history(),
        ];
    }
}
