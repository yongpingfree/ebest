<?php

namespace App\Filament\Auth;

/** Login page of the normal-user panel (/app). */
class AppLogin extends Login
{
    protected function loginPanelId(): string
    {
        return 'app';
    }
}
