<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('price_comparison', function (Blueprint $table) {
            $table->id();
            $table->string('category');
            $table->string('umall_title');
            $table->string('umall_sku');
            $table->string('ebest_title');
            $table->string('ebest_sku');
            $table->decimal('umall_unit_price', 10, 2);
            $table->string('umall_unit', 16);
            $table->decimal('ebest_unit_price', 10, 2);
            $table->string('ebest_unit', 16);
            $table->decimal('price_diff_pct', 8, 1);          // (ebest / umall - 1) * 100
            $table->string('lower_side', 8);                   // umall | ebest | equal
            $table->dateTime('load_time')->index();
            $table->index(['category', 'umall_sku']);
        });

        Schema::create('price_comparison_runs', function (Blueprint $table) {
            $table->id();
            $table->string('trigger');                         // manual | scheduled
            $table->string('status')->default('queued');       // queued | running | done | failed
            $table->text('message')->nullable();
            $table->unsignedInteger('rows')->nullable();
            $table->dateTime('started_at')->nullable();
            $table->dateTime('finished_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('price_comparison_runs');
        Schema::dropIfExists('price_comparison');
    }
};
