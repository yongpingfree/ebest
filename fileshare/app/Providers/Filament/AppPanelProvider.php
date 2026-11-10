<?php

namespace App\Providers\Filament;

use Filament\Http\Middleware\Authenticate;
use Filament\Http\Middleware\AuthenticateSession;
use Filament\Http\Middleware\DisableBladeIconComponents;
use Filament\Http\Middleware\DispatchServingFilamentEvent;
use Filament\Pages\Dashboard;
use Filament\Panel;
use Filament\PanelProvider;
use Filament\Support\Colors\Color;
use Filament\Widgets\AccountWidget;
use Filament\Widgets\FilamentInfoWidget;
use Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse;
use Illuminate\Cookie\Middleware\EncryptCookies;
use Illuminate\Foundation\Http\Middleware\PreventRequestForgery;
use Illuminate\Routing\Middleware\SubstituteBindings;
use Illuminate\Session\Middleware\StartSession;
use Illuminate\View\Middleware\ShareErrorsFromSession;

class AppPanelProvider extends PanelProvider
{
    public function panel(Panel $panel): Panel
    {
return $panel
    ->id('app')
    ->path('app')
    ->login(\App\Filament\Auth\AppLogin::class)
            ->navigationItems([
                \Filament\Navigation\NavigationItem::make('Admin')
                    ->url(fn (): string => url('/admin'))
                    ->icon('heroicon-o-cog-6-tooth')
                    ->visible(fn (): bool => (bool) auth()->user()?->canUpload())
                    ->sort(100),
            ])
            ->brandName('eBest')
            ->brandLogo(fn () => new \Illuminate\Support\HtmlString('<div style="display:flex;align-items:center;gap:0.75rem"><img src="'.asset('images/ebest.png').'" alt="eBest" style="height:2.5rem"><span style="font-size:1.1rem;font-weight:600;white-space:nowrap">eBest Internal File Share Service</span></div>'))
            ->brandLogoHeight('2.5rem')
    ->colors(['primary' => Color::Blue])
    ->discoverResources(in: app_path('Filament/App/Resources'), for: 'App\Filament\App\Resources')
    ->discoverPages(in: app_path('Filament/App/Pages'), for: 'App\Filament\App\Pages')
    ->pages([
       \App\Filament\App\Pages\Files::class,
    ])                       // remove Pages\Dashboard::class
    ->discoverWidgets(in: app_path('Filament/App/Widgets'), for: 'App\Filament\App\Widgets')
    ->widgets([])
            ->middleware([
                EncryptCookies::class,
                AddQueuedCookiesToResponse::class,
                StartSession::class,
                AuthenticateSession::class,
                ShareErrorsFromSession::class,
                PreventRequestForgery::class,
                SubstituteBindings::class,
                DisableBladeIconComponents::class,
                DispatchServingFilamentEvent::class,
            ])
            ->authMiddleware([
                Authenticate::class,
	    ]);
 
    // keep the generated ->middleware([...]) and ->authMiddleware([...]) blocks unchanged

/*	    return $panel
            ->id('app')
            ->path('app')
            ->colors([
                'primary' => Color::Amber,
            ])
            ->discoverResources(in: app_path('Filament/App/Resources'), for: 'App\Filament\App\Resources')
            ->discoverPages(in: app_path('Filament/App/Pages'), for: 'App\Filament\App\Pages')
            ->pages([
                Dashboard::class,
            ])
            ->discoverWidgets(in: app_path('Filament/App/Widgets'), for: 'App\Filament\App\Widgets')
            ->widgets([
                AccountWidget::class,
                FilamentInfoWidget::class,
            ])
            ->middleware([
                EncryptCookies::class,
                AddQueuedCookiesToResponse::class,
                StartSession::class,
                AuthenticateSession::class,
                ShareErrorsFromSession::class,
                PreventRequestForgery::class,
                SubstituteBindings::class,
                DisableBladeIconComponents::class,
                DispatchServingFilamentEvent::class,
            ])
            ->authMiddleware([
                Authenticate::class,
	    ]);*/
    }
}
