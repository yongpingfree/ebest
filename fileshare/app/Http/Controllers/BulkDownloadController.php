<?php

namespace App\Http\Controllers;

use App\Models\SharedFile;
use Illuminate\Http\Request;
use ZipArchive;

/**
 * Download a selection of files and/or folders (Google Drive style):
 *  - exactly one file  -> the file itself
 *  - anything else     -> one zip; a selected folder keeps its structure under its own name
 */
class BulkDownloadController extends Controller
{
    public function __invoke(Request $request)
    {
        $user = $request->user();
        abort_unless($user && $user->is_active, 403);

        $items = array_filter((array) $request->input('items', []), 'is_string');
        abort_if(empty($items), 422, 'Nothing selected.');

        $base = rtrim(config('fileshare.published'), '/') . '/';

        // zip entry name => absolute file path
        $entries = [];
        $folderNames = [];
        $fileCount = 0;

        $available = fn () => SharedFile::query()
            ->where('status', 'done')
            ->where('published_expires_at', '>', now());

        foreach ($items as $item) {
            if (str_starts_with($item, 'f:')) {
                $file = $available()->find((int) substr($item, 2));
                if ($file && is_file($base . $file->path)) {
                    $entries[$this->unique($entries, basename($file->path))] = $base . $file->path;
                    $fileCount++;
                    $single = $file;
                }
            } elseif (str_starts_with($item, 'd:')) {
                $folder = $this->cleanFolder(substr($item, 2));
                if ($folder === '') {
                    continue;
                }
                $parent = str_contains($folder, '/') ? dirname($folder) . '/' : '';
                $folderNames[] = basename($folder);

                $files = $available()
                    ->where('path', 'like', addcslashes($folder . '/', '%_\\') . '%')
                    ->orderBy('path')
                    ->get();

                foreach ($files as $f) {
                    if (! is_file($base . $f->path)) {
                        continue;
                    }
                    // keep the structure from the selected folder down, e.g. "b/sub/x.pdf"
                    $name = substr($f->path, strlen($parent));
                    $entries[$this->unique($entries, $name)] = $base . $f->path;
                }
            }
        }

        abort_if(empty($entries), 404, 'Nothing available to download.');

        if (count($items) === 1 && $fileCount === 1 && isset($single)) {
            return response()->download($base . $single->path, basename($single->path));
        }

        $tmp = tempnam(sys_get_temp_dir(), 'dl_');
        $zip = new ZipArchive();
        abort_unless($zip->open($tmp, ZipArchive::OVERWRITE) === true, 500, 'Cannot create zip.');

        foreach ($entries as $name => $abs) {
            $zip->addFile($abs, $name);
            $zip->setCompressionName($name, ZipArchive::CM_STORE);   // PDFs are already compressed
        }
        $zip->close();

        $zipName = (count($items) === 1 && count($folderNames) === 1)
            ? $folderNames[0] . '.zip'
            : 'download-' . now()->format('Ymd-His') . '.zip';

        return response()->download($tmp, $zipName, ['Content-Type' => 'application/zip'])
            ->deleteFileAfterSend(true);
    }

    private function cleanFolder(string $path): string
    {
        return implode('/', array_filter(
            explode('/', str_replace('\\', '/', $path)),
            fn ($p) => $p !== '' && $p !== '.' && $p !== '..'
        ));
    }

    /** Avoid two entries with the same name: "a.pdf" -> "a (1).pdf". */
    private function unique(array $entries, string $name): string
    {
        if (! isset($entries[$name])) {
            return $name;
        }
        $info = pathinfo($name);
        $dir = ($info['dirname'] ?? '.') === '.' ? '' : $info['dirname'] . '/';
        $ext = isset($info['extension']) ? '.' . $info['extension'] : '';
        for ($i = 1; ; $i++) {
            $candidate = "{$dir}{$info['filename']} ({$i}){$ext}";
            if (! isset($entries[$candidate])) {
                return $candidate;
            }
        }
    }
}
