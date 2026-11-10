<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PdfSetting extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'auto_refresh' => 'boolean',
            'changed_at' => 'datetime',
        ];
    }
}
