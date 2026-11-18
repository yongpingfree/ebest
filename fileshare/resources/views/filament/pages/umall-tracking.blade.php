<x-filament-panels::page>
    <div wire:poll.5s>
        @php($i = $this->getInfo())
        <x-filament::section heading="Status">
            <p><strong>{{ $i['running'] ? 'RUNNING' : 'IDLE' }}</strong></p>
            <p style="margin-top:.5rem">Last load: {{ $i['last_load'] ?? 'never' }} ({{ $i['last_rows'] }} rows) &middot; Total rows in table: {{ $i['total_rows'] }}</p>
            <p style="margin-top:.5rem;font-size:.85rem;opacity:.7">Runs automatically once a day around 12:00.</p>
        </x-filament::section>

        <x-filament::section heading="Run history" style="margin-top:1rem;">
            <table style="width:100%; font-size:.875rem; border-collapse:collapse;">
                <thead>
                    <tr style="text-align:left; border-bottom:1px solid #8884;">
                        <th style="padding:.4rem">Started</th><th>Finished</th><th>Trigger</th><th>By</th><th>Status</th><th>Rows</th><th>Message</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse ($i['history'] as $h)
                        <tr style="border-bottom:1px solid #8882;">
                            <td style="padding:.4rem">{{ $h->started_at ?? $h->created_at }}</td>
                            <td>{{ $h->finished_at ?? '—' }}</td>
                            <td>{{ $h->trigger }}</td>
                            <td>{{ $h->trigger === 'scheduled' ? 'auto' : ($h->user_name ?? '—') }}</td>
                            <td>{{ strtoupper($h->status) }}</td>
                            <td>{{ $h->rows ?? '—' }}</td>
                            <td>{{ \Illuminate\Support\Str::limit($h->message, 120) }}</td>
                        </tr>
                    @empty
                        <tr><td colspan="7" style="padding:.4rem">No runs yet.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </x-filament::section>

        <x-filament::section heading="Price comparison history (umall vs ebest)" style="margin-top:1rem;">
            <p style="font-size:.85rem;opacity:.7;margin-bottom:.5rem">Runs automatically once a day after {{ sprintf('%02d:%02d', config('fileshare.compare_start_hour'), config('fileshare.compare_start_minute')) }}. Fetches ebest items only and compares them with the umall data already loaded; umall is never fetched by this job. {{ $i['cmp_running'] ? 'Currently RUNNING.' : '' }}</p>
            <table style="width:100%; font-size:.875rem; border-collapse:collapse;">
                <thead>
                    <tr style="text-align:left; border-bottom:1px solid #8884;">
                        <th style="padding:.4rem">Started</th><th>Finished</th><th>Trigger</th><th>By</th><th>Status</th><th>Rows</th><th>Message</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse ($i['cmp_history'] as $h)
                        <tr style="border-bottom:1px solid #8882;">
                            <td style="padding:.4rem">{{ $h->started_at ?? $h->created_at }}</td>
                            <td>{{ $h->finished_at ?? '—' }}</td>
                            <td>{{ $h->trigger }}</td>
                            <td>{{ $h->trigger === 'scheduled' ? 'auto' : ($h->user_name ?? '—') }}</td>
                            <td>{{ strtoupper($h->status) }}</td>
                            <td>{{ $h->rows ?? '—' }}</td>
                            <td>{{ \Illuminate\Support\Str::limit($h->message, 120) }}</td>
                        </tr>
                    @empty
                        <tr><td colspan="7" style="padding:.4rem">No runs yet.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </x-filament::section>
    </div>

    <div style="display:flex;gap:.75rem;flex-wrap:wrap">
        <x-filament::button wire:click="run" icon="heroicon-o-arrow-path" :disabled="! $this->canRun()">
            Fetch &amp; load data
        </x-filament::button>
        <x-filament::button wire:click="runComparison" color="gray" icon="heroicon-o-scale" :disabled="! $this->canRun()">
            Run price comparison
        </x-filament::button>
        <x-filament::button wire:click="recompare" color="gray" icon="heroicon-o-arrow-path-rounded-square" :disabled="! $this->canRun()">
            Update comparison only
        </x-filament::button>
    </div>
</x-filament-panels::page>
