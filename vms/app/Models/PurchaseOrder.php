<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class PurchaseOrder extends Model
{
    public const STATUS = ['draft' => '草稿', 'submitted' => '已提交', 'approved' => '已审核', 'exception' => '异常'];

    protected $guarded = ['id'];

    protected $casts = [
        'purchase_date' => 'date', 'eta_date' => 'date', 'sync_stock' => 'boolean',
        'submitted_at' => 'datetime', 'exported_at' => 'datetime',
    ];

    public function vendor(): BelongsTo
    {
        return $this->belongsTo(Vendor::class);
    }

    public function lines(): HasMany
    {
        return $this->hasMany(PurchaseOrderLine::class);
    }

    public function histories(): HasMany
    {
        return $this->hasMany(PurchaseOrderHistory::class)->latest('id');
    }

    public function statusLabel(): string
    {
        return __(self::STATUS[$this->status] ?? $this->status);
    }

    public function editableByVendor(): bool
    {
        return $this->status === 'draft';
    }

    public function logStatus(?string $from, string $to, ?string $note, string $actor): void
    {
        $this->histories()->create(['from_status' => $from, 'to_status' => $to, 'note' => $note, 'actor' => $actor]);
    }
}
