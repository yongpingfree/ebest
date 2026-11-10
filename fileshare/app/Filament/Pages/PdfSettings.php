<?php

namespace App\Filament\Pages;

use App\Services\PdfSettingsService as S;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Filament\Schemas\Concerns\InteractsWithSchemas;
use Filament\Schemas\Contracts\HasSchemas;
use Filament\Schemas\Schema;

class PdfSettings extends Page implements HasSchemas
{
    use InteractsWithSchemas;

    protected string $view = 'filament.pages.pdf-settings';

    protected static ?string $navigationLabel = 'PDF settings';
    protected static ?string $title = 'PDF protection settings';
    protected static ?int $navigationSort = 2;

    public ?array $data = [];

    // PDF passwords are for administrators only.
    public static function canAccess(): bool
    {
        return auth()->user()?->isAdmin() ?? false;
    }

    public function mount(S $s): void
    {
        $this->form->fill([
            'user_password' => $s->get(S::USER),
            'user_auto' => $s->autoRefresh(S::USER),
            'owner_password' => $s->get(S::OWNER),
            'owner_auto' => $s->autoRefresh(S::OWNER),
            'hours' => $s->get(S::HOURS),
        ]);
    }

    public function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('user_password')->label('User password')->required()->minLength(4)
                    ->helperText('Needed to open the protected PDF.'),
                Toggle::make('user_auto')->label('Auto-refresh user password every day (midnight)'),
                TextInput::make('owner_password')->label('Owner password')->required()->minLength(4)
                    ->different('user_password')
                    ->helperText('Must differ from the user password.'),
                Toggle::make('owner_auto')->label('Auto-refresh owner password every week (Monday midnight)'),
                TextInput::make('hours')->label('Validity (hours)')->numeric()->minValue(0.1)->required(),
            ])
            ->statePath('data');
    }

    public function save(S $s): void
    {
        $d = $this->form->getState();
        $uid = auth()->id();

        $s->set(S::USER, (string) $d['user_password'], (bool) $d['user_auto'], $uid);
        $s->set(S::OWNER, (string) $d['owner_password'], (bool) $d['owner_auto'], $uid);
        $s->set(S::HOURS, (string) $d['hours'], null, $uid);

        Notification::make()->title('Settings saved')->success()->send();
    }

    public function getHistory(): array
    {
        $s = app(S::class);
        $labels = [S::USER => 'User password', S::OWNER => 'Owner password', S::HOURS => 'Validity hours'];

        return $s->history()->map(fn ($h) => [
            'when' => $h->created_at->timezone(config('app.timezone'))->format('Y-m-d H:i:s'),
            'item' => $labels[$h->key] ?? $h->key,
            'old' => $s->plain($h->key, $h->old_value),
            'new' => $s->plain($h->key, $h->new_value),
            'by' => $h->source === 'auto' ? 'auto' : ($h->user?->name ?? 'admin'),
        ])->all();
    }
}
