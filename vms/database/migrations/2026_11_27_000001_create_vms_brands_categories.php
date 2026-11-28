<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 供应商品牌:注册时至少创建一个并上传品牌图;eBest 员工回填 WMS/OMS 中建好的品牌 id
        Schema::create('brands', function (Blueprint $t) {
            $t->id();
            $t->foreignId('vendor_id')->constrained('vendors')->cascadeOnDelete();
            $t->string('name');
            $t->string('name_en')->nullable();
            $t->string('image_path')->nullable();
            $t->string('image_url', 500)->nullable();
            $t->string('ebest_brand_id', 40)->nullable()->index();
            $t->string('ebest_brand_id_by')->nullable();
            $t->timestamp('ebest_brand_id_at')->nullable();
            $t->timestamps();
            $t->unique(['vendor_id', 'name']);
        });

        // 分类:从 OMS 导出(见 database/oms/export_categories.sql)后用 vms:load-categories 载入;id 即 OMS 分类 id
        Schema::create('categories', function (Blueprint $t) {
            $t->unsignedBigInteger('id')->primary();
            $t->unsignedBigInteger('parent_id')->nullable()->index();
            $t->string('name_zh')->nullable();
            $t->string('name_en')->nullable();
            $t->unsignedTinyInteger('status')->default(1);
            $t->integer('position')->default(0);
            $t->timestamps();
        });

        Schema::table('vendors', function (Blueprint $t) {
            $t->timestamp('submit_notified_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('vendors', function (Blueprint $t) {
            $t->dropColumn('submit_notified_at');
        });
        Schema::dropIfExists('categories');
        Schema::dropIfExists('brands');
    }
};
