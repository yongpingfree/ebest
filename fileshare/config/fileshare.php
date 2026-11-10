<?php
return [
    'originals' => env('FILESHARE_ORIGINALS'),
'tmp' => env('FILESHARE_TMP', '/srv/fileshare/tmp'),
    'published' => env('FILESHARE_PUBLISHED'),
    'original_retention_hours' => (float) env('ORIGINAL_RETENTION_HOURS', 36),
    'python' => env('PDF_TRANSFORM_PYTHON'),
    // Permission (see settings/permissions.json) required to see the Export button on the user list.
    'export_permission' => env('FILESHARE_EXPORT_PERMISSION', 'users'),
    'script' => env('PDF_TRANSFORM_SCRIPT'),
];
