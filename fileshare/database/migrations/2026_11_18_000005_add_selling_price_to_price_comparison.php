<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('price_comparison', function (Blueprint $table) {
            $table->decimal('umall_price', 10, 2)->nullable();   // selling price of the pack (AUD, lower of regular/promo)
            $table->decimal('ebest_price', 10, 2)->nullable();
        });
        Schema::table('price_comparison_unmatched', function (Blueprint $table) {
            $table->decimal('price', 10, 2)->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('price_comparison', function (Blueprint $table) {
            $table->dropColumn(['umall_price', 'ebest_price']);
        });
        Schema::table('price_comparison_unmatched', function (Blueprint $table) {
            $table->dropColumn('price');
        });
    }
};
