<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('download_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->unsignedBigInteger('shared_file_id');   // no FK: keep history if a file is deleted
            $table->timestamp('downloaded_at')->index();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('download_logs');
    }
};
