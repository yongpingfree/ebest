<?php

namespace App\Filament\Resources\SharedFiles\Tables;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Table;
use App\Jobs\ProcessSharedFile;
use Filament\Actions\Action;
use Filament\Tables\Columns\TextColumn;

class SharedFilesTable
{
    public static function configure(Table $table): Table
    {
	return $table
    ->defaultSort('uploaded_at', 'desc')
    ->columns([
        TextColumn::make('path')->searchable()->wrap(),
        TextColumn::make('status')->badge()->color(fn ($state) => match ($state) {
            'done' => 'success', 'failed' => 'danger', 'processing' => 'warning', default => 'gray',
        }),
        TextColumn::make('size')->formatStateUsing(fn ($state) => number_format($state / 1024, 1) . ' KB'),
        TextColumn::make('uploaded_at')->dateTime()->sortable(),
        TextColumn::make('published_expires_at')->label('Visible until')->dateTime(),
        TextColumn::make('original_expires_at')->label('Original kept until')->dateTime(),
        TextColumn::make('error')->limit(60)->toggleable(isToggledHiddenByDefault: true),
    ])
    ->recordActions([
        Action::make('retry')
            ->icon('heroicon-o-arrow-path')
            ->visible(fn ($record) => $record->status === 'failed')
            ->action(fn ($record) => ProcessSharedFile::dispatch($record->id)),
    ])
	    ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
		])
	    ]);
	
    }
}
