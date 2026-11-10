<?php

namespace App\Http\Controllers;

use App\Models\SharedFile;

class FileDownloadController extends Controller
{
    public function __invoke(SharedFile $file)
    {
        $user = auth()->user();
        abort_unless($user && $user->is_active, 403);
        abort_unless($file->status === 'done' && $file->published_expires_at->isFuture(), 404);

        $abs = rtrim(config('fileshare.published'), '/') . '/' . $file->path;
        abort_unless(is_file($abs), 404);

        return response()->download($abs, basename($file->path));
    }
}
