<?php

namespace App\Filament\Widgets;

use App\Models\DownloadLog;
use App\Models\SharedFile;
use Carbon\CarbonPeriod;
use Filament\Widgets\ChartWidget;

class FileActivityChart extends ChartWidget
{
    protected ?string $heading = 'File activity - past 30 days';

    protected int | string | array $columnSpan = 'full';

    protected ?string $maxHeight = '320px';

    protected function getType(): string
    {
        return 'line';
    }

    protected function getData(): array
    {
        $start = now()->subDays(29)->startOfDay();
        $days = collect(CarbonPeriod::create($start, now()->startOfDay()))
            ->map(fn ($d) => $d->format('Y-m-d'));

        $uploaded = SharedFile::where('uploaded_at', '>=', $start)->pluck('uploaded_at')
            ->countBy(fn ($t) => $t->format('Y-m-d'));

        $logs = DownloadLog::where('downloaded_at', '>=', $start)->get(['shared_file_id', 'downloaded_at'])
            ->groupBy(fn ($l) => $l->downloaded_at->format('Y-m-d'));

        return [
            'datasets' => [
                [
                    'label' => 'Files uploaded',
                    'data' => $days->map(fn ($d) => $uploaded[$d] ?? 0)->all(),
                    'borderColor' => '#f59e0b',
                    'backgroundColor' => '#f59e0b',
                ],
                [
                    'label' => 'Files downloaded (distinct)',
                    'data' => $days->map(fn ($d) => isset($logs[$d]) ? $logs[$d]->pluck('shared_file_id')->unique()->count() : 0)->all(),
                    'borderColor' => '#3b82f6',
                    'backgroundColor' => '#3b82f6',
                ],
                [
                    'label' => 'Total downloads (times)',
                    'data' => $days->map(fn ($d) => isset($logs[$d]) ? $logs[$d]->count() : 0)->all(),
                    'borderColor' => '#10b981',
                    'backgroundColor' => '#10b981',
                ],
            ],
            'labels' => $days->map(fn ($d) => substr($d, 5))->all(),
        ];
    }

    protected function getOptions(): array
    {
        return [
            'scales' => ['y' => ['beginAtZero' => true, 'ticks' => ['precision' => 0]]],
        ];
    }
}
