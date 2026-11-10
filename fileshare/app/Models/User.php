<?php

namespace App\Models;

use Filament\Models\Contracts\FilamentUser;
use Filament\Panel;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable implements FilamentUser
{
    use HasApiTokens, HasFactory, Notifiable;

    public const ROLE_ADMIN = 'admin';       // user management + upload files + settings
    public const ROLE_OPERATOR = 'operator'; // upload files, no user management
    public const ROLE_USER = 'user';         // download files only

    public const ROLES = [
        self::ROLE_ADMIN => 'Administrator',
        self::ROLE_OPERATOR => 'Operator',
        self::ROLE_USER => 'Normal user',
    ];

    protected $fillable = ['name', 'email', 'password', 'is_admin', 'role', 'permissions'];

    protected $hidden = ['password', 'remember_token'];

    protected static function booted(): void
    {
        // `role` is the source of truth; the legacy `is_admin` column is kept in step with it,
        // and setting only `is_admin` (e.g. from tinker) still works.
        static::saving(function (User $user) {
            if ($user->isDirty('is_admin') && ! $user->isDirty('role')) {
                if ($user->is_admin) {
                    $user->role = self::ROLE_ADMIN;
                } elseif ($user->role === self::ROLE_ADMIN) {
                    $user->role = self::ROLE_USER;
                }
            }

            $user->is_admin = ($user->role ?? self::ROLE_USER) === self::ROLE_ADMIN;
        });
    }

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'is_admin' => 'boolean',
            'is_active' => 'boolean',
            'last_login_at' => 'datetime',
            'permissions' => 'array',
        ];
    }

    public function isAdmin(): bool
    {
        return $this->role === self::ROLE_ADMIN;
    }

    public function hasPermission(string $permission): bool
    {
        return in_array($permission, $this->permissions ?? [], true);
    }

    public function isOperator(): bool
    {
        return $this->role === self::ROLE_OPERATOR;
    }

    /** May upload files (administrators and operators). */
    public function canUpload(): bool
    {
        return $this->isAdmin() || $this->isOperator();
    }

    public function canAccessPanel(Panel $panel): bool
    {
        return match ($panel->getId()) {
            'admin' => $this->canUpload(),   // admin and operator; user management is restricted separately
            'app'   => true,
            default => false,
        };
    }
}
