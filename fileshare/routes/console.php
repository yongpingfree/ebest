<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Daily cut-off at midnight (app timezone); owner password is only rotated once per week.
Illuminate\Support\Facades\Schedule::command('fileshare:rotate-passwords')->dailyAt('00:00');
