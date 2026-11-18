<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('umall_tracking_runs', function (Blueprint $table) {
            $table->id();
            $table->string('trigger');                       // manual | scheduled
            $table->foreignId('user_id')->nullable();
            $table->string('status')->default('queued');     // queued | running | done | failed
            $table->text('message')->nullable();
            $table->unsignedInteger('rows')->nullable();
            $table->dateTime('started_at')->nullable();
            $table->dateTime('finished_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('umall_tracking_runs');
    }
};
