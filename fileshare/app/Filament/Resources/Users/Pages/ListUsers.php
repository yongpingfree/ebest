<?php

namespace App\Filament\Resources\Users\Pages;

use App\Filament\Resources\Users\UserResource;
use App\Models\User;
use App\Support\Permissions;
use Filament\Actions\Action;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;

class ListUsers extends ListRecords
{
    protected static string $resource = UserResource::class;

    // Administrators only: operators and normal users get 403 even on a direct link.
    public static function canAccess(array $parameters = []): bool
    {
        return auth()->user()?->isAdmin() ?? false;
    }

    protected function getHeaderActions(): array
    {
        return [
            Action::make('export')
                ->label('Export')
                ->icon('heroicon-o-arrow-down-tray')
                ->visible(fn () => auth()->user()?->hasPermission(Permissions::exportUsers()) ?? false)
                ->action(function () {
                    // Re-check on the server so a hidden button can't be triggered directly.
                    abort_unless(auth()->user()?->hasPermission(Permissions::exportUsers()), 403);

                    return response()->streamDownload(function () {
                        $out = fopen('php://output', 'w');
                        fwrite($out, "\xEF\xBB\xBF"); // UTF-8 BOM so Excel reads Chinese names
                        fputcsv($out, ['Name', 'Email', 'Role', 'Last login', 'Created']);
                        User::orderBy('id')->each(fn (User $u) => fputcsv($out, [
                            $u->name, $u->email, User::ROLES[$u->role] ?? $u->role,
                            $u->last_login_at?->toDateTimeString(), $u->created_at?->toDateTimeString(),
                        ]));
                        fclose($out);
                    }, 'users-'.now()->format('Ymd-His').'.csv', ['Content-Type' => 'text/csv']);
                }),
            CreateAction::make(),
        ];
    }
}
