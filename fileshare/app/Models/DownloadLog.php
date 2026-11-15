<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DownloadLog extends Model
{
    public $timestamps = false;

    protected $guarded = [];

    protected function casts(): array
    {
        return ['downloaded_at' => 'datetime'];
    }

    /** Record one download event per file. */
    public static function record(?int $userId, iterable $fileIds): void
    {
        $now = now();
        $rows = [];
        foreach ($fileIds as $id) {
            $rows[] = ['user_id' => $userId, 'shared_file_id' => $id, 'downloaded_at' => $now];
        }
        if ($rows) {
            static::insert($rows);
        }
    }
}
