<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('price_comparison', function (Blueprint $table) {
            $table->string('umall_promo_note', 500)->nullable();   // multi-buy / 满折 / 满赠 text not reflected in the compared price
            $table->string('ebest_promo_note', 500)->nullable();
        });
        Schema::table('price_comparison_unmatched', function (Blueprint $table) {
            $table->string('promo_note', 500)->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('price_comparison', function (Blueprint $table) {
            $table->dropColumn(['umall_promo_note', 'ebest_promo_note']);
        });
        Schema::table('price_comparison_unmatched', function (Blueprint $table) {
            $table->dropColumn('promo_note');
        });
    }
};
