<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SharedFile extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'is_pdf' => 'boolean',
            'uploaded_at' => 'datetime',
            'processed_at' => 'datetime',
            'original_expires_at' => 'datetime',
            'published_expires_at' => 'datetime',
        ];
    }
}
