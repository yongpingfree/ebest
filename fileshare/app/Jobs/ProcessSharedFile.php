<?php

namespace App\Jobs;

use App\Models\SharedFile;
use App\Services\PdfSettingsService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Symfony\Component\Process\Process;

class ProcessSharedFile implements ShouldQueue
{
    use Queueable;

    public int $timeout = 600;
    public int $tries = 2;

    public function __construct(public int $fileId) {}

    public function handle(): void
    {
        $file = SharedFile::find($this->fileId);
        if (! $file) {
            return;
        }

        $file->update(['status' => 'processing', 'error' => null]);

        $src = rtrim(config('fileshare.originals'), '/') . '/' . $file->path;
        $dst = rtrim(config('fileshare.published'), '/') . '/' . $file->path;
        File::ensureDirectoryExists(dirname($dst), 02775);

        if ($file->is_pdf) {
            $settings = app(PdfSettingsService::class);
            $tmp = $dst . '.part';
            $process = new Process([
                config('fileshare.python'),
                config('fileshare.script'),
                $src,
                $settings->get(PdfSettingsService::USER),
                '-o', $tmp,
                '--hours', $settings->get(PdfSettingsService::HOURS),
                '--owner-password', $settings->get(PdfSettingsService::OWNER),
            ]);
            $process->setTimeout(600);
            $process->run();

            if (! $process->isSuccessful() || ! file_exists($tmp)) {
                @unlink($tmp);
                // Full, untruncated output; passwords are never logged.
                Log::channel('transform')->error('PDF transform failed', [
                    'file' => $file->path,
                    'exit_code' => $process->getExitCode(),
                    'command' => implode(' ', [basename((string) config('fileshare.script')), $src, '<user-pw>', '-o', $tmp, '--hours', $settings->get(PdfSettingsService::HOURS), '--owner-password', '<owner-pw>']),
                    'stderr' => $process->getErrorOutput(),
                    'stdout' => $process->getOutput(),
                ]);
                $file->update([
                    'status' => 'failed',
                    'error' => Str::limit(trim($process->getErrorOutput() ?: $process->getOutput()) ?: 'Transform failed', 2000),
                ]);
                return;
            }

            rename($tmp, $dst);   // users never see a half-written file
        } else {
            File::copy($src, $dst);
        }

        $file->update(['status' => 'done', 'processed_at' => now()]);
    }

    public function failed(\Throwable $e): void
    {
        SharedFile::whereKey($this->fileId)->update([
            'status' => 'failed',
            'error' => Str::limit($e->getMessage(), 2000),
        ]);
    }
}
