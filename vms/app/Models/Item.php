<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Item extends Model
{
    public const STATUS = [
        'draft' => '草稿', 'submitted' => '已提交', 'returned' => '已退回',
        'imported' => '已导入OMS', 'listed' => '已上架',
    ];

    protected $guarded = ['id'];

    protected $casts = ['data' => 'array', 'submitted_at' => 'datetime', 'exported_at' => 'datetime'];

    public function vendor(): BelongsTo
    {
        return $this->belongsTo(Vendor::class);
    }

    public function images(): HasMany
    {
        return $this->hasMany(ItemImage::class)->orderBy('sort')->orderBy('id');
    }

    public function histories(): HasMany
    {
        return $this->hasMany(ItemHistory::class)->latest('id');
    }

    public function statusLabel(): string
    {
        return self::STATUS[$this->status] ?? $this->status;
    }

    public function val(string $key, $default = null)
    {
        return $this->data[$key] ?? $default;
    }

    public function editableByVendor(): bool
    {
        return in_array($this->status, ['draft', 'returned'], true);
    }

    public function logStatus(?string $from, string $to, ?string $note, string $actor): void
    {
        $this->histories()->create(['from_status' => $from, 'to_status' => $to, 'note' => $note, 'actor' => $actor]);
    }
}
