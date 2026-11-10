<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Current value of each setting: user_password | owner_password | hours
        Schema::create('pdf_settings', function (Blueprint $table) {
            $table->id();
            $table->string('key')->unique();
            $table->text('value');                        // passwords stored encrypted
            $table->boolean('auto_refresh')->default(true); // ignored for "hours"
            $table->timestamp('changed_at');
            $table->timestamps();
        });

        Schema::create('pdf_setting_histories', function (Blueprint $table) {
            $table->id();
            $table->string('key')->index();
            $table->text('old_value')->nullable();       // passwords stored encrypted
            $table->text('new_value');
            $table->string('source');                    // manual | auto
            $table->foreignId('changed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('created_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pdf_setting_histories');
        Schema::dropIfExists('pdf_settings');
    }
};
