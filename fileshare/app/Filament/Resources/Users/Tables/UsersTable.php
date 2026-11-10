<?php

namespace App\Filament\Resources\Users\Tables;

use Filament\Actions\DeleteAction;
use Filament\Actions\EditAction;
use App\Models\User;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class UsersTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('name')->searchable()->sortable(),
                TextColumn::make('email')->searchable()->sortable(),
                TextColumn::make('role')->label('Role')->badge()
                    ->formatStateUsing(fn ($state) => User::ROLES[$state] ?? $state)
                    ->color(fn ($state) => match ($state) {
                        User::ROLE_ADMIN => 'danger',
                        User::ROLE_OPERATOR => 'warning',
                        default => 'gray',
                    }),
                TextColumn::make('last_login_at')->label('Last login')->dateTime()->sortable()->placeholder('Never'),
                TextColumn::make('created_at')->dateTime()->sortable(),
            ])
            ->recordActions([EditAction::make(), DeleteAction::make()]);
    }
}
