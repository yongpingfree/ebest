<?php

namespace App\Services;

use App\Jobs\ProcessSharedFile;
use App\Models\SharedFile;
use Illuminate\Support\Facades\File;
use ZipArchive;

class FileIngestService
{
    /** Copy one file into originals/ and queue it for processing. */
    public function ingestFile(string $sourceAbs, string $relativePath): SharedFile
    {
        $rel = $this->cleanPath($relativePath);
        $dest = rtrim(config('fileshare.originals'), '/') . '/' . $rel;

        File::ensureDirectoryExists(dirname($dest), 02775);
        File::copy($sourceAbs, $dest);

        $now = now();
        $file = SharedFile::updateOrCreate(
            ['path' => $rel],
            [
                'size' => filesize($dest),
                'is_pdf' => str_ends_with(strtolower($rel), '.pdf'),
                'status' => 'pending',
                'error' => null,
                'uploaded_by' => auth()->id(),
                'uploaded_at' => $now,
                'processed_at' => null,
                'original_expires_at' => $now->copy()->addMinutes((int) round(config('fileshare.original_retention_hours') * 60)),
                'published_expires_at' => $now->copy()->endOfDay(),   // 23:59:59 today (app timezone)
            ]
        );

        ProcessSharedFile::dispatch($file->id);

        return $file;
    }

    /** Unpack a zip, keeping its folder structure under $folder. Returns number of files. */
    public function ingestZip(string $zipAbs, string $folder = ''): int
    {
        $zip = new ZipArchive();
        if ($zip->open($zipAbs) !== true) {
            throw new \RuntimeException('Cannot open zip file.');
        }

        $tmpDir = rtrim(config('fileshare.tmp', '/srv/fileshare/tmp'), '/');
        File::ensureDirectoryExists($tmpDir, 02775);
        $count = 0;

        for ($i = 0; $i < $zip->numFiles; $i++) {
            $name = $zip->getNameIndex($i);
            if (str_ends_with($name, '/') || str_contains($name, '__MACOSX/') || basename($name) === '.DS_Store') {
                continue;   // skip folders and macOS junk
            }

            $tmp = $tmpDir . '/' . uniqid('zip_', true);
            $in = $zip->getStream($name);
            $out = fopen($tmp, 'w');
            stream_copy_to_stream($in, $out);
            fclose($in);
            fclose($out);

            $this->ingestFile($tmp, trim($folder . '/' . $name, '/'));
            @unlink($tmp);
            $count++;
        }

        $zip->close();
        return $count;
    }

    /** Normalise a relative path and block "../" tricks. */
    public function cleanPath(string $path): string
    {
        $parts = array_filter(
            explode('/', str_replace('\\', '/', $path)),
            fn ($p) => $p !== '' && $p !== '.' && $p !== '..'
        );

        if (empty($parts)) {
            throw new \InvalidArgumentException('Invalid file path.');
        }

        return implode('/', $parts);
    }
}
