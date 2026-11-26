<?php

namespace App\Console\Commands;

use App\Models\StaffUser;
use Illuminate\Console\Command;

class CreateStaff extends Command
{
    protected $signature = 'vms:create-staff {email} {name} {--role=operator : admin|operator}';

    protected $description = '创建 eBest 员工账号(admin 可查看完整银行信息)';

    public function handle(): int
    {
        $pw = $this->secret('密码(至少 10 位)');
        if (strlen((string) $pw) < 10) {
            $this->error('密码至少 10 位');

            return self::FAILURE;
        }
        StaffUser::updateOrCreate(['email' => $this->argument('email')], ['name' => $this->argument('name'), 'password' => $pw, 'role' => $this->option('role'), 'is_active' => true]);
        $this->info('已保存员工账号');

        return self::SUCCESS;
    }
}
