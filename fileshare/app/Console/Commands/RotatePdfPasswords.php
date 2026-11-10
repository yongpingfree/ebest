<?php

namespace App\Console\Commands;

use App\Services\PdfSettingsService;
use Illuminate\Console\Command;

class RotatePdfPasswords extends Command
{
    protected $signature = 'fileshare:rotate-passwords';
    protected $description = 'Auto-refresh the PDF user (daily) and owner (weekly) passwords when due';

    public function handle(PdfSettingsService $settings): int
    {
        $rotated = $settings->rotateDue();
        $this->info($rotated ? 'Rotated: ' . implode(', ', $rotated) : 'Nothing due.');

        return self::SUCCESS;
    }
}
