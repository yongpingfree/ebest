<x-filament-panels::page>
    @php
        $listing = $this->getListing();
        $allSelected = (count($listing['folders']) + count($listing['files'])) > 0
            && collect($listing['folders'])->every(fn ($f) => in_array('d:' . $listing['prefix'] . $f, $selected))
            && collect($listing['files'])->every(fn ($f) => in_array('f:' . $f->id, $selected));
    @endphp

    <x-filament::section>
        <div style="margin-bottom:1rem; padding:.6rem .8rem; border:1px solid #f59e0b; border-radius:.5rem;">
            🔑 PDF password: <strong style="font-family:monospace; user-select:all;">{{ $this->getPdfPassword() }}</strong>
            <span style="opacity:.7;">(changes daily)</span>
        </div>

        @if ($this->canSeePasswordHistory())
            <x-filament::section heading="PDF user password history (past 3 days)" collapsible collapsed style="margin-bottom:1rem;">
                <table style="width:100%; font-size:.875rem; border-collapse:collapse;">
                    <thead>
                        <tr style="text-align:left; border-bottom:1px solid #8884;">
                            <th style="padding:.4rem">When</th><th>PDF user password</th><th>Changed by</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse ($this->getPasswordHistory() as $row)
                            <tr style="border-bottom:1px solid #8882;">
                                <td style="padding:.4rem">{{ $row['when'] }}</td>
                                <td style="font-family:monospace">{{ $row['password'] }}</td>
                                <td>{{ $row['by'] }}</td>
                            </tr>
                        @empty
                            <tr><td colspan="3" style="padding:.4rem">No changes in the past 3 days.</td></tr>
                        @endforelse
                    </tbody>
                </table>
            </x-filament::section>
        @endif

        <div style="margin-bottom:1rem;">
            <a href="#" wire:click.prevent="goTo('')">Home</a>
            @foreach ($listing['crumbs'] as $crumbPath => $name)
                / <a href="#" wire:click.prevent="goTo(@js($crumbPath))">{{ $name }}</a>
            @endforeach
        </div>

        @if (count($selected))
            <div style="margin-bottom:1rem; display:flex; gap:1rem; align-items:center;">
                <strong>{{ count($selected) }} selected</strong>
                <form method="POST" action="{{ route('files.bulk') }}" style="margin:0;">
                    @csrf
                    @foreach ($selected as $sel)
                        <input type="hidden" name="items[]" value="{{ $sel }}">
                    @endforeach
                    <x-filament::button type="submit" icon="heroicon-o-arrow-down-tray" size="sm">Download</x-filament::button>
                </form>
                <a href="#" wire:click.prevent="clearSelection">Clear</a>
            </div>
        @endif

        @if (empty($listing['folders']) && empty($listing['files']))
            <p>No files available today.</p>
        @else
            <table style="width:100%; border-collapse:collapse;">
                <thead>
                    <tr style="text-align:left; border-bottom:1px solid #e5e7eb;">
                        <th style="padding:.5rem; width:2rem;">
                            <input type="checkbox" wire:click="toggleAll" title="Select all" @checked($allSelected)>
                        </th>
                        <th style="padding:.5rem;">Name</th>
                        <th style="padding:.5rem;">Size</th>
                        <th style="padding:.5rem;">Available until</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach ($listing['folders'] as $folder)
                        <tr style="border-bottom:1px solid #f3f4f6;">
                            <td style="padding:.5rem;">
                                <input type="checkbox" wire:model.live="selected" value="d:{{ $listing['prefix'] . $folder }}">
                            </td>
                            <td style="padding:.5rem;">
                                📁 <a href="#" wire:click.prevent="openFolder(@js($folder))">{{ $folder }}</a>
                            </td>
                            <td></td><td></td>
                        </tr>
                    @endforeach

                    @foreach ($listing['files'] as $file)
                        <tr style="border-bottom:1px solid #f3f4f6;">
                            <td style="padding:.5rem;">
                                <input type="checkbox" wire:model.live="selected" value="f:{{ $file->id }}">
                            </td>
                            <td style="padding:.5rem;">
                                📄 <a href="{{ route('files.download', $file) }}">{{ basename($file->path) }}</a>
                            </td>
                            <td style="padding:.5rem;">{{ number_format($file->size / 1024, 1) }} KB</td>
                            <td style="padding:.5rem;">{{ $file->published_expires_at->format('Y-m-d H:i:s') }}</td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        @endif
    </x-filament::section>
</x-filament-panels::page>
