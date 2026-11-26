<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;

class Vendor extends Authenticatable
{
    public const PROFILE_FIELDS = [
        'application_type', 'abn', 'name', 'short_name', 'street_address', 'postal_address', 'phone',
        'payment_terms_days', 'bsb', 'account_number', 'bank_institution', 'bank_branch', 'bank_account_name',
        'contact_name', 'contact_phone', 'auth_name', 'auth_phone', 'auth_date',
    ];

    protected $guarded = ['id'];

    protected $hidden = ['password', 'remember_token', 'verification_code', 'account_number'];

    protected function casts(): array
    {
        return [
            'password' => 'hashed',
            'account_number' => 'encrypted',
            'email_verified_at' => 'datetime',
            'verification_expires_at' => 'datetime',
            'submitted_at' => 'datetime',
            'reviewed_at' => 'datetime',
            'auth_date' => 'date',
            'auth_confirmed' => 'boolean',
            'pending_changes' => 'array',
        ];
    }

    public function items(): HasMany
    {
        return $this->hasMany(Item::class);
    }

    public function purchaseOrders(): HasMany
    {
        return $this->hasMany(PurchaseOrder::class);
    }

    public function histories(): HasMany
    {
        return $this->hasMany(VendorHistory::class)->latest();
    }

    public function isApproved(): bool
    {
        return $this->status === 'approved';
    }

    public function statusLabel(): string
    {
        return ['incomplete' => '资料未提交', 'pending' => '待审核', 'approved' => '已通过', 'rejected' => '已驳回'][$this->status] ?? $this->status;
    }

    /** 账号只显示后 3 位 */
    public static function maskAccount(?string $n): string
    {
        $n = (string) $n;

        return $n === '' ? '' : str_repeat('*', max(strlen($n) - 3, 0)).substr($n, -3);
    }

    public function display(): string
    {
        return $this->name ?: $this->email;
    }
}
