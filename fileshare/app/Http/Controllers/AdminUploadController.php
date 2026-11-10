<?php

namespace App\Http\Controllers;

use App\Services\FileIngestService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/** Receives one file at a time from the admin drag-and-drop uploader, keeping its relative path. */
class AdminUploadController extends Controller
{
    public function __invoke(Request $request, FileIngestService $ingest): JsonResponse
    {
        $user = $request->user();
        abort_unless($user && $user->canUpload() && $user->is_active, 403);

        $request->validate([
            'file' => ['required', 'file'],
            'path' => ['required', 'string', 'max:1000'],      // relative path, e.g. reports/2026/a.pdf
            'folder' => ['nullable', 'string', 'max:500'],     // optional target folder
            'extract_zip' => ['nullable', 'boolean'],
        ]);

        $file = $request->file('file');
        $relative = trim(trim((string) $request->input('folder'), '/') . '/' . $request->input('path'), '/');

        try {
            if ($request->boolean('extract_zip') && str_ends_with(strtolower($relative), '.zip')) {
                $count = $ingest->ingestZip($file->getRealPath(), trim(dirname($relative), './'));
            } else {
                $ingest->ingestFile($file->getRealPath(), $relative);
                $count = 1;
            }
        } catch (\Throwable $e) {
            return response()->json(['ok' => false, 'error' => $e->getMessage()], 422);
        }

        return response()->json(['ok' => true, 'count' => $count, 'path' => $relative]);
    }
}
