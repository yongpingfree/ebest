<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 供应商在「已导入 OMS / 已上架」后修改了标题或图片的时间;运营在 OMS 同步后清除
        Schema::table('items', function (Blueprint $t) {
            $t->timestamp('post_listing_changed_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('items', function (Blueprint $t) {
            $t->dropColumn('post_listing_changed_at');
        });
    }
};
