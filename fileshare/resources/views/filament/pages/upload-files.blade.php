<x-filament-panels::page>
    {{ $this->form }}

    <x-filament::section heading="PDF user password history (past 3 days)" collapsible collapsed>
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

    <div
        x-data="folderUploader({ url: @js(route('admin.upload')), token: @js(csrf_token()) })"
        style="margin-top:1.5rem;"
    >
        <div
            x-on:dragover.prevent="over = true"
            x-on:dragleave.prevent="over = false"
            x-on:drop.prevent="over = false; onDrop($event)"
            :style="over ? 'border-color:#f59e0b; background:#f59e0b14' : ''"
            style="border:2px dashed #9ca3af; border-radius:.75rem; padding:2.5rem 1rem; text-align:center;"
        >
            <p style="font-weight:600;">Drag &amp; drop files or an entire folder here</p>
            <p style="opacity:.7; margin:.25rem 0 1rem;">Folder structure is kept.</p>

            <input type="file" multiple x-ref="files" style="display:none" x-on:change="addList($event.target.files); $event.target.value=''">
            <input type="file" webkitdirectory x-ref="dir" style="display:none" x-on:change="addList($event.target.files); $event.target.value=''">

            <x-filament::button type="button" color="gray" x-on:click="$refs.files.click()">Choose files</x-filament::button>
            <x-filament::button type="button" color="gray" x-on:click="$refs.dir.click()">Choose folder</x-filament::button>
        </div>

        <template x-if="items.length">
            <div style="margin-top:1rem;">
                <p style="margin-bottom:.5rem;">
                    <span x-text="doneCount"></span> / <span x-text="items.length"></span> uploaded
                    <span x-show="failedCount" style="color:#dc2626;">, <span x-text="failedCount"></span> failed</span>
                </p>
                <div style="max-height:18rem; overflow:auto; font-size:.875rem; border:1px solid #8884; border-radius:.5rem;">
                    <template x-for="it in items" :key="it.path">
                        <div style="display:flex; justify-content:space-between; gap:1rem; padding:.3rem .6rem; border-bottom:1px solid #8882;">
                            <span x-text="it.path" style="word-break:break-all;"></span>
                            <span x-text="it.state" :style="it.state==='failed' ? 'color:#dc2626' : (it.state==='done' ? 'color:#16a34a' : '')" :title="it.error"></span>
                        </div>
                    </template>
                </div>
            </div>
        </template>
    </div>

    <script>
        document.addEventListener('alpine:init', () => {
            Alpine.data('folderUploader', (cfg) => ({
                over: false,
                items: [],
                running: false,

                get doneCount() { return this.items.filter(i => i.state === 'done').length; },
                get failedCount() { return this.items.filter(i => i.state === 'failed').length; },

                // Drop: walk directories with the File System Entries API.
                async onDrop(e) {
                    // entries must be grabbed synchronously, before any await
                    const entries = [...e.dataTransfer.items]
                        .map(i => (i.webkitGetAsEntry ? i.webkitGetAsEntry() : null))
                        .filter(Boolean);
                    const found = [];
                    for (const en of entries) await this.walk(en, found);
                    this.enqueue(found);
                },

                async walk(entry, out) {
                    if (entry.isFile) {
                        const file = await new Promise((res, rej) => entry.file(res, rej));
                        out.push({ file, path: entry.fullPath.replace(/^\/+/, '') });
                    } else if (entry.isDirectory) {
                        const reader = entry.createReader();
                        let batch;
                        do {   // readEntries returns results in chunks until empty
                            batch = await new Promise((res, rej) => reader.readEntries(res, rej));
                            for (const child of batch) await this.walk(child, out);
                        } while (batch.length);
                    }
                },

                // "Choose files / folder" buttons
                addList(list) {
                    this.enqueue([...list].map(f => ({ file: f, path: f.webkitRelativePath || f.name })));
                },

                enqueue(found) {
                    for (const f of found) {
                        if (f.file.name === '.DS_Store' || f.path.includes('__MACOSX/')) continue;
                        this.items.push({ file: f.file, path: f.path, state: 'queued', error: '' });
                    }
                    this.run();
                },

                async run() {
                    if (this.running) return;
                    this.running = true;
                    const worker = async () => {
                        let it;
                        while ((it = this.items.find(i => i.state === 'queued'))) {
                            it.state = 'uploading';
                            try { await this.send(it); it.state = 'done'; }
                            catch (err) { it.state = 'failed'; it.error = err.message; }
                        }
                    };
                    await Promise.all([worker(), worker(), worker()]);
                    this.running = false;
                    if (this.items.some(i => i.state === 'queued')) this.run();
                },

                async send(it) {
                    const fd = new FormData();
                    fd.append('file', it.file);
                    fd.append('path', it.path);
                    fd.append('folder', this.$wire.data.folder || '');
                    fd.append('extract_zip', this.$wire.data.extract_zip ? '1' : '0');
                    const res = await fetch(cfg.url, {
                        method: 'POST',
                        headers: { 'X-CSRF-TOKEN': cfg.token, 'Accept': 'application/json' },
                        body: fd,
                        credentials: 'same-origin',
                    });
                    if (!res.ok) {
                        let msg = 'HTTP ' + res.status;
                        try { const j = await res.json(); msg = j.error || j.message || msg; } catch (e) {}
                        throw new Error(msg);
                    }
                },
            }));
        });
    </script>
</x-filament-panels::page>
