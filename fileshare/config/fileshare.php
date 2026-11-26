<?php
return [
    'originals' => env('FILESHARE_ORIGINALS'),
'tmp' => env('FILESHARE_TMP', '/srv/fileshare/tmp'),
    'published' => env('FILESHARE_PUBLISHED'),
    'original_retention_hours' => (float) env('ORIGINAL_RETENTION_HOURS', 36),
    'python' => env('PDF_TRANSFORM_PYTHON'),
    // Permission (see settings/permissions.json) required to see the Export button on the user list.
    'export_permission' => env('FILESHARE_EXPORT_PERMISSION', 'users'),
    // Access key for /report/1 (reports/report1.php)
    'report1_key' => env('REPORT1_KEY', 'abcde'),
    // Access key for /report/2 (reports/report2.php) - separate from report1
    'report2_key' => env('REPORT2_KEY', 'fghij'),
    // Umall vs ebest comparison: scripts, umall json folder written by UM tracking script1 (never fetched by this job), daily start hour
    'compare_dir' => env('COMPARE_TOOL_DIR', base_path('compare-tool')),
    'compare_umall_dir' => env('COMPARE_UMALL_DIR', storage_path('app/umall/script1_output')),
    'compare_start_hour' => (int) env('COMPARE_START_HOUR', 13),
    'compare_start_minute' => (int) env('COMPARE_START_MINUTE', 30),
    // Umall tracking scripts (admin > Umall tracking)
    'umall_dir' => env('UMALL_TOOL_DIR', base_path('umall-tool')),
    // free-shipping threshold lookup (report 2); token is a secret, set it in .env only
    'umall_api_token' => env('UMALL_API_TOKEN', ''),
    'umall_pinkage_url' => env('UMALL_PINKAGE_URL', 'https://b.umall.com.au/api/h5app/wxapp/delivery/getPinkageList'),
    'umall_python' => env('UMALL_PYTHON', 'python3'),
    'script' => env('PDF_TRANSFORM_SCRIPT'),
];
