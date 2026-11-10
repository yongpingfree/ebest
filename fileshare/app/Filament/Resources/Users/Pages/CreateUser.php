<?php

namespace App\Filament\Resources\Users\Pages;

use App\Filament\Resources\Users\UserResource;
use Filament\Resources\Pages\CreateRecord;

class CreateUser extends CreateRecord
{
    protected static string $resource = UserResource::class;

    // Administrators only: operators and normal users get 403 even on a direct link.
    public static function canAccess(array $parameters = []): bool
    {
        return auth()->user()?->isAdmin() ?? false;
    }
}
