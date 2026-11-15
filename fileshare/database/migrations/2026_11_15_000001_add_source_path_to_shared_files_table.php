<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('shared_files', function (Blueprint $table) {
            // Original file name when it differs from the published one (Excel .xls/.xlsx -> .xlsm).
            $table->string('source_path', 1000)->nullable()->after('path');
        });
    }

    public function down(): void
    {
        Schema::table('shared_files', function (Blueprint $table) {
            $table->dropColumn('source_path');
        });
    }
};
