<x-filament-panels::page>
    {{ $this->form }}

    <div style="margin-top: 1rem;">
        <x-filament::button wire:click="save" wire:loading.attr="disabled" wire:target="save" icon="heroicon-o-check">
            Save
        </x-filament::button>
    </div>

    <x-filament::section heading="Change history" style="margin-top: 1.5rem;">
        <table style="width:100%; font-size:.875rem; border-collapse:collapse;">
            <thead>
                <tr style="text-align:left; border-bottom:1px solid #8884;">
                    <th style="padding:.4rem">When</th><th>Item</th><th>Old</th><th>New</th><th>By</th>
                </tr>
            </thead>
            <tbody>
                @forelse ($this->getHistory() as $row)
                    <tr style="border-bottom:1px solid #8882;">
                        <td style="padding:.4rem">{{ $row['when'] }}</td>
                        <td>{{ $row['item'] }}</td>
                        <td>{{ $row['old'] ?? '—' }}</td>
                        <td>{{ $row['new'] }}</td>
                        <td>{{ $row['by'] }}</td>
                    </tr>
                @empty
                    <tr><td colspan="5" style="padding:.4rem">No changes yet.</td></tr>
                @endforelse
            </tbody>
        </table>
    </x-filament::section>
</x-filament-panels::page>
