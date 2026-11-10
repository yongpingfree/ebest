
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
public function up(): void
{
    Schema::create('shared_files', function (Blueprint $table) {
        $table->id();
        $table->string('path')->unique();                 // relative path, e.g. reports/finance/a.pdf
        $table->unsignedBigInteger('size')->default(0);
        $table->boolean('is_pdf')->default(false);
        $table->string('status')->default('pending');     // pending | processing | done | failed
        $table->text('error')->nullable();
        $table->foreignId('uploaded_by')->nullable()->constrained('users')->nullOnDelete();
        $table->timestamp('uploaded_at');
        $table->timestamp('processed_at')->nullable();
        $table->timestamp('original_expires_at');
        $table->timestamp('published_expires_at');
        $table->timestamps();
    });
}

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('shared_files');
    }
};
