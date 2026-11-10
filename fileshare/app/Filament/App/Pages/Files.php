<?php

namespace App\Filament\App\Pages;

use App\Models\SharedFile;
use Filament\Pages\Page;
use Livewire\Attributes\Url;


class Files extends Page
{
    protected string $view = 'filament.app.pages.files';
    protected static ?string $navigationLabel = 'Files';
    protected static ?string $title = 'Files';
    protected static string $routePath = '/';     // makes /app open this page

    #[Url]
    public string $path = '';

    /** Selected items, kept while browsing: "d:<folder path>" or "f:<file id>". */
    public array $selected = [];

    public function clearSelection(): void
    {
        $this->selected = [];
    }

    /** Select / unselect everything listed in the current folder. */
    public function toggleAll(): void
    {
        $listing = $this->getListing();
        $keys = array_merge(
            array_map(fn ($f) => 'd:' . $listing['prefix'] . $f, $listing['folders']),
            array_map(fn ($f) => 'f:' . $f->id, $listing['files']),
        );

        $this->selected = count(array_diff($keys, $this->selected)) === 0
            ? array_values(array_diff($this->selected, $keys))
            : array_values(array_unique(array_merge($this->selected, $keys)));
    }

    public function getPdfPassword(): string
    {
        return app(\App\Services\PdfSettingsService::class)->get(\App\Services\PdfSettingsService::USER);
    }

    public function openFolder(string $name): void
    {
        $this->path = trim($this->path . '/' . $name, '/');
    }

    public function goTo(string $path): void
    {
        $this->path = trim($path, '/');
    }

    public function getListing(): array
    {
        $path = implode('/', array_filter(explode('/', $this->path), fn ($p) => $p !== '' && $p !== '..'));
        $prefix = $path === '' ? '' : $path . '/';

        $files = SharedFile::query()
            ->where('status', 'done')
            ->where('published_expires_at', '>', now())
            ->when($prefix !== '', fn ($q) => $q->where('path', 'like', addcslashes($prefix, '%_\\') . '%'))
            ->orderBy('path')
            ->get();

        $folders = [];
        $items = [];
        foreach ($files as $f) {
            $rest = substr($f->path, strlen($prefix));
            if (str_contains($rest, '/')) {
                $folders[explode('/', $rest)[0]] = true;
            } else {
                $items[] = $f;
            }
        }

        $crumbs = [];
        $acc = '';
        foreach (array_filter(explode('/', $path)) as $part) {
            $acc = ltrim($acc . '/' . $part, '/');
            $crumbs[$acc] = $part;
        }

        return ['folders' => array_keys($folders), 'files' => $items, 'crumbs' => $crumbs, 'prefix' => $prefix];
    }
}
