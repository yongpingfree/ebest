<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('umall_tracking', function (Blueprint $table) {
            $table->id();
            $table->string('category');
            $table->string('item_name');
            $table->decimal('price_aud', 10, 2)->nullable();
            $table->decimal('promotion_price_aud', 10, 2)->nullable();
            $table->integer('available_quantity')->nullable();
            $table->dateTime('load_time')->index();
            $table->index(['category', 'item_name']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('umall_tracking');
    }
};
