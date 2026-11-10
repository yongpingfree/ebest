<?php

namespace App\Filament\Pages;

use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Pages\Page;
use Filament\Schemas\Concerns\InteractsWithSchemas;
use Filament\Schemas\Contracts\HasSchemas;
use Filament\Schemas\Schema;

class UploadFiles extends Page implements HasSchemas
{
    use InteractsWithSchemas;

    // keep the generated line, e.g.:
    protected string $view = 'filament.pages.upload-files';

    protected static ?string $navigationLabel = 'Upload files';
    protected static ?int $navigationSort = 1;

    public ?array $data = [];

    public function mount(): void
    {
        $this->form->fill(['extract_zip' => true]);
    }

    public function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('folder')
                    ->label('Target folder (optional)')
                    ->placeholder('e.g. reports/finance')
                    ->helperText('Files are placed in this folder. Leave empty for the top level.'),
                Toggle::make('extract_zip')
                    ->label('Unpack .zip files and keep their folder structure'),
            ])
            ->statePath('data');
    }
}
