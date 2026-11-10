<?php

namespace App\Filament\Resources\Users\Schemas;

use App\Models\User;
use App\Support\Permissions;
use Filament\Forms\Components\CheckboxList;
use Filament\Forms\Components\Radio;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;

class UserForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema->components([
            TextInput::make('name')->required()->maxLength(255),
            TextInput::make('email')->email()->required()->unique(ignoreRecord: true)
                ->autocomplete(false),   // don't let the browser fill in the admin's own saved login
            TextInput::make('password')
                ->password()->revealable()
                ->autocomplete('new-password')   // ...and don't autofill the admin's saved password here
                ->required(fn (string $operation) => $operation === 'create')
                ->dehydrated(fn ($state) => filled($state))   // leave blank on edit = keep current password
                ->minLength(8),
            // Radio buttons are plain HTML, so all three roles are always visible (no JS dropdown needed).
            Radio::make('role')
                ->label('Role')
                ->options(User::ROLES)
                ->descriptions([
                    User::ROLE_ADMIN => 'User management, upload files, PDF settings.',
                    User::ROLE_OPERATOR => 'Upload files only; no user management.',
                    User::ROLE_USER => 'Download files only.',
                ])
                ->default(User::ROLE_USER)
                ->required(),
            CheckboxList::make('permissions')
                ->label('Permissions')
                ->options(Permissions::all())
                ->columns(3)->searchable()->bulkToggleable(),
        ]);
    }
}
