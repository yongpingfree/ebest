<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AuditLog extends Model
{
    protected $guarded = ['id'];

    public static function record(string $actor, string $action, ?string $subject = null, ?string $detail = null): void
    {
        static::create(['actor' => $actor, 'action' => $action, 'subject' => $subject, 'detail' => $detail, 'ip' => request()?->ip()]);
    }
}
