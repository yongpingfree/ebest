<?php

namespace App\Services;

use App\Models\PdfSetting;
use App\Models\PdfSettingHistory;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Str;

/**
 * Holds the PDF transform settings (user password, owner password, validity hours)
 * and keeps a change history.
 *
 * - user_password : auto-refreshed daily (at midnight) unless auto_refresh is off
 * - owner_password: auto-refreshed weekly unless auto_refresh is off
 * - hours         : 24 by default
 * A manual change by an admin switches auto_refresh off for that password
 * (the admin can switch it on again from the settings page).
 */
class PdfSettingsService
{
    public const USER = 'user_password';
    public const OWNER = 'owner_password';
    public const HOURS = 'hours';

    public const SECRETS = [self::USER, self::OWNER];

    /** Current value; creates the default on first use. */
    public function get(string $key): string
    {
        $row = PdfSetting::where('key', $key)->first() ?? $this->initialise($key);

        return $this->isSecret($key) ? Crypt::decryptString($row->value) : $row->value;
    }

    public function autoRefresh(string $key): bool
    {
        return (bool) (PdfSetting::where('key', $key)->first() ?? $this->initialise($key))->auto_refresh;
    }

    /** Admin change. Records history only when something actually changed. */
    public function set(string $key, string $value, ?bool $autoRefresh = null, ?int $userId = null): void
    {
        $row = PdfSetting::where('key', $key)->first() ?? $this->initialise($key);

        if ($autoRefresh !== null && $this->isSecret($key) && $row->auto_refresh !== $autoRefresh) {
            $row->update(['auto_refresh' => $autoRefresh]);
        }

        if ($value !== $this->get($key)) {
            $this->write($row, $value, 'manual', $userId);
        }
    }

    /** Called by the scheduler: rotate whatever is due and has auto-refresh on. */
    public function rotateDue(): array
    {
        $rotated = [];
        $now = now();

        foreach ([self::USER => $now->copy()->startOfDay(), self::OWNER => $now->copy()->startOfWeek()] as $key => $cutoff) {
            $row = PdfSetting::where('key', $key)->first() ?? $this->initialise($key);
            if ($row->auto_refresh && $row->changed_at->lt($cutoff)) {
                $this->write($row, $this->randomPassword(), 'auto', null);
                $rotated[] = $key;
            }
        }

        return $rotated;
    }

    public function history(int $limit = 100)
    {
        return PdfSettingHistory::with('user')->latest('created_at')->latest('id')->limit($limit)->get();
    }

    /** Value as shown in the history list (decrypts passwords). */
    public function plain(string $key, ?string $stored): ?string
    {
        if ($stored === null) {
            return null;
        }

        return $this->isSecret($key) ? Crypt::decryptString($stored) : $stored;
    }

    public function randomPassword(int $length = 16): string
    {
        return Str::password($length, symbols: false);
    }

    private function isSecret(string $key): bool
    {
        return in_array($key, self::SECRETS, true);
    }

    private function initialise(string $key): PdfSetting
    {
        $value = $key === self::HOURS ? '24' : Crypt::encryptString($this->randomPassword());

        $row = PdfSetting::create(['key' => $key, 'value' => $value, 'auto_refresh' => true, 'changed_at' => now()]);

        PdfSettingHistory::create([
            'key' => $key, 'old_value' => null, 'new_value' => $value, 'source' => 'auto', 'created_at' => now(),
        ]);

        return $row;
    }

    private function write(PdfSetting $row, string $value, string $source, ?int $userId): void
    {
        $stored = $this->isSecret($row->key) ? Crypt::encryptString($value) : $value;

        PdfSettingHistory::create([
            'key' => $row->key,
            'old_value' => $row->value,
            'new_value' => $stored,
            'source' => $source,
            'changed_by' => $userId,
            'created_at' => now(),
        ]);

        $row->update(['value' => $stored, 'changed_at' => now()]);
    }
}
