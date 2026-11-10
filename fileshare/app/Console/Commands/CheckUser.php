<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Hash;

/**
 * Diagnose / repair a user's sign-in:
 *   php artisan fileshare:check-user alice@example.com                       show role, active flag, hash status
 *   php artisan fileshare:check-user alice@example.com --test='the password' does this password match the stored hash?
 *   php artisan fileshare:check-user alice@example.com --set='new password'  set a new password (stored hashed)
 */
class CheckUser extends Command
{
    protected $signature = 'fileshare:check-user {email} {--test=} {--set=}';
    protected $description = 'Show a user\'s role and password status, test a password, or set a new one';

    public function handle(): int
    {
        $user = User::where('email', $this->argument('email'))->first()
            ?? User::whereRaw('lower(email) = ?', [strtolower($this->argument('email'))])->first();

        if (! $user) {
            $this->error('No user with that email (emails are case-sensitive in the database).');
            return self::FAILURE;
        }

        if (filled($this->option('set'))) {
            $user->password = $this->option('set');   // 'hashed' cast stores it hashed
            $user->save();
            $this->info('Password updated.');
            $user->refresh();
        }

        $hash = (string) $user->getAuthPassword();
        $this->table(['field', 'value'], [
            ['id / email', $user->id . ' / ' . $user->email],
            ['role', (string) $user->role],
            ['is_admin', $user->is_admin ? 'true' : 'false'],
            ['is_active', $user->is_active ? 'true' : 'false'],
            ['password stored', $hash === '' ? 'NO (empty)' : 'yes, ' . strlen($hash) . ' chars, starts ' . substr($hash, 0, 4)],
            ['looks hashed', Hash::isHashed($hash) ? 'yes' : 'NO (plain text or corrupt)'],
            ['can open /admin', $user->canUpload() ? 'yes' : 'no'],
            ['last login', (string) ($user->last_login_at ?? 'never')],
        ]);

        if (filled($this->option('test'))) {
            $ok = $hash !== '' && Hash::check($this->option('test'), $hash);
            $ok ? $this->info('Password MATCHES the stored hash.') : $this->error('Password does NOT match the stored hash.');
        }

        return self::SUCCESS;
    }
}
