<?php

namespace Database\Seeders;

use App\Models\StaffUser;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $email = env('VMS_STAFF_EMAIL');
        $pw = env('VMS_STAFF_PASSWORD');
        if ($email && $pw) {
            StaffUser::firstOrCreate(['email' => $email], ['name' => 'VMS Admin', 'password' => $pw, 'role' => 'admin']);
        }
    }
}
