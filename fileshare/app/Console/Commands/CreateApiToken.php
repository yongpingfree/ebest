<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;

class CreateApiToken extends Command
{
    protected $signature = 'api:token {email : User email the token belongs to}
                            {--name=api-client : Token name}
                            {--years=20 : Validity in years}';

    protected $description = 'Create a long-lived Sanctum API token for a user';

    public function handle(): int
    {
        $user = User::where('email', $this->argument('email'))->first();
        if (! $user) {
            $this->error('User not found.');
            return self::FAILURE;
        }

        $years = (int) $this->option('years');
        $token = $user->createToken($this->option('name'), ['*'], now()->addYears($years));

        $this->info("Token valid until {$token->accessToken->expires_at}");
        $this->line('Shown once, store it safely:');
        $this->line($token->plainTextToken);

        return self::SUCCESS;
    }
}
