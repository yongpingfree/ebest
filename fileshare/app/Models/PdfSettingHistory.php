<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PdfSettingHistory extends Model
{
    public $timestamps = false;

    protected $guarded = [];

    protected function casts(): array
    {
        return ['created_at' => 'datetime'];
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'changed_by');
    }
}
