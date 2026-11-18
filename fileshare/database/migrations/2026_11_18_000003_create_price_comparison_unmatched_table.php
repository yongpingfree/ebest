<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('price_comparison_unmatched', function (Blueprint $table) {
            $table->id();
            $table->string('side', 8);                 // umall | ebest
            $table->string('category');
            $table->string('title', 500);
            $table->string('sku');
            $table->decimal('unit_price', 10, 2)->nullable();
            $table->string('unit', 16)->nullable();
            $table->dateTime('load_time')->index();
            $table->index(['load_time', 'side', 'category']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('price_comparison_unmatched');
    }
};
