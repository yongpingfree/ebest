<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Daily cut-off at midnight (app timezone); owner password is only rotated once per week.
Illuminate\Support\Facades\Schedule::command('fileshare:rotate-passwords')->dailyAt('00:00');

// UM tracking: once a day at a random time between 11:00 and 13:00 (app timezone).
// The command is checked every minute and only runs when today's random time has passed.
Illuminate\Support\Facades\Schedule::command('umall:run --due')->everyMinute()->withoutOverlapping();

// Umall vs ebest comparison: once a day after 13:00 (checked every minute, runs once per day).
Illuminate\Support\Facades\Schedule::command('compare:run --due')->everyMinute()->withoutOverlapping();
