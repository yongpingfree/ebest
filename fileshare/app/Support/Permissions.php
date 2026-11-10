<?php

namespace App\Support;

class Permissions
{
    /** Permission names from settings/permissions.json (file format: {a,b,c}). */
    public static function all(): array
    {
        $raw = @file_get_contents(base_path('settings/permissions.json')) ?: '';
        $decoded = json_decode($raw, true);
        $names = is_array($decoded)
            ? $decoded
            : array_map('trim', explode(',', trim($raw, " \t\n\r{}[]")));

        $names = array_values(array_unique(array_filter($names, 'strlen')));

        return array_combine($names, $names);
    }

    /** Permission that controls the Export button on the user list (configurable). */
    public static function exportUsers(): string
    {
        return config('fileshare.export_permission', 'users');
    }
}
