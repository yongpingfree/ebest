<?php

namespace App\Filament\Auth;

use Filament\Auth\Pages\Login as BaseLogin;
use Filament\Facades\Filament;
use Filament\Forms\Components\Checkbox;
use Filament\Forms\Components\TextInput;
use Filament\Models\Contracts\FilamentUser;
use Filament\Schemas\Components\Component;
use Illuminate\Contracts\Auth\Authenticatable;

/**
 * Login page that keeps people signed in: "Remember me" is on by default, and the fields carry
 * the autocomplete hints that let the browser save and refill the credentials.
 */
class Login extends BaseLogin
{
    /** The panel this login page belongs to (admin panel by default; see AppLogin). */
    protected function loginPanelId(): string
    {
        return 'admin';
    }

    // Check access against THIS page's panel, not whichever panel happens to be "current", so a
    // normal user is judged by the user panel's rules at /app and not refused by the admin panel's.
    protected function isUserAllowedToAccessPanel(Authenticatable $user): bool
    {
        if (! ($user instanceof FilamentUser)) {
            return true;
        }

        return $user->canAccessPanel(Filament::getPanel($this->loginPanelId()));
    }

    protected function getEmailFormComponent(): Component
    {
        return TextInput::make('email')
            ->label(__('filament-panels::auth/pages/login.form.email.label'))
            ->email()
            ->required()
            ->autocomplete('username')
            ->extraInputAttributes(['name' => 'email'])
            ->autofocus();
    }

    protected function getPasswordFormComponent(): Component
    {
        // a real `name` helps password managers recognise the field
        return parent::getPasswordFormComponent()
            ->extraInputAttributes(['name' => 'password']);
    }

    protected function getRememberFormComponent(): Component
    {
        return Checkbox::make('remember')
            ->label(__('filament-panels::auth/pages/login.form.remember.label'))
            ->default(true);
    }
}
