<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('sessions', function (Blueprint $t) {
            $t->string('id')->primary();
            $t->foreignId('user_id')->nullable()->index();
            $t->string('ip_address', 45)->nullable();
            $t->text('user_agent')->nullable();
            $t->longText('payload');
            $t->integer('last_activity')->index();
        });

        Schema::create('staff_users', function (Blueprint $t) {
            $t->id();
            $t->string('name');
            $t->string('email')->unique();
            $t->string('password');
            $t->string('role')->default('operator'); // admin | operator
            $t->boolean('is_active')->default(true);
            $t->rememberToken();
            $t->timestamps();
        });

        Schema::create('vendors', function (Blueprint $t) {
            $t->id();
            $t->string('email')->unique();
            $t->string('password');
            $t->timestamp('email_verified_at')->nullable();
            $t->string('verification_code')->nullable();      // hash
            $t->timestamp('verification_expires_at')->nullable();
            $t->unsignedTinyInteger('verification_attempts')->default(0);
            // 注册审核状态: incomplete 未提交资料 | pending 待审核 | approved 已通过 | rejected 已驳回
            $t->string('status')->default('incomplete')->index();
            $t->string('application_type')->default('new');   // new | amend
            $t->string('abn', 11)->nullable();
            $t->string('name')->nullable();                   // 发票上的正式名称
            $t->string('short_name')->nullable();
            $t->string('street_address')->nullable();
            $t->string('postal_address')->nullable();
            $t->string('phone')->nullable();
            $t->unsignedSmallInteger('payment_terms_days')->nullable();
            $t->string('bsb')->nullable();
            $t->text('account_number')->nullable();           // encrypted
            $t->string('bank_institution')->nullable();
            $t->string('bank_branch')->nullable();
            $t->string('bank_account_name')->nullable();
            $t->string('contact_name')->nullable();
            $t->string('contact_phone')->nullable();
            $t->boolean('auth_confirmed')->default(false);
            $t->string('auth_name')->nullable();
            $t->string('auth_phone')->nullable();
            $t->date('auth_date')->nullable();
            $t->timestamp('submitted_at')->nullable();
            $t->timestamp('reviewed_at')->nullable();
            $t->text('reject_reason')->nullable();
            $t->string('wms_vendor_ref')->nullable();         // WMS 中的供应商对应关系
            $t->json('pending_changes')->nullable();          // 修改已有供应商时的待审核内容
            $t->rememberToken();
            $t->timestamps();
        });

        Schema::create('vendor_histories', function (Blueprint $t) {
            $t->id();
            $t->foreignId('vendor_id')->constrained()->cascadeOnDelete();
            $t->string('event');
            $t->text('note')->nullable();
            $t->json('snapshot')->nullable();
            $t->string('actor')->nullable();
            $t->timestamps();
        });

        Schema::create('items', function (Blueprint $t) {
            $t->id();
            $t->foreignId('vendor_id')->constrained()->cascadeOnDelete();
            // draft 草稿 | submitted 已提交 | returned 已退回 | imported 已导入OMS(待上架) | listed 已上架
            $t->string('status')->default('draft')->index();
            $t->string('sku_no')->nullable()->index();
            $t->string('title')->nullable();
            $t->json('data');
            $t->text('return_reason')->nullable();
            $t->string('oms_item_no')->nullable();
            $t->timestamp('submitted_at')->nullable();
            $t->timestamp('exported_at')->nullable();
            $t->timestamps();
            $t->unique(['vendor_id', 'sku_no']);
        });

        Schema::create('item_images', function (Blueprint $t) {
            $t->id();
            $t->foreignId('item_id')->constrained()->cascadeOnDelete();
            $t->string('kind')->index();
            $t->string('path');
            $t->string('url', 1024);
            $t->string('original_name')->nullable();
            $t->unsignedSmallInteger('width')->nullable();
            $t->unsignedSmallInteger('height')->nullable();
            $t->unsignedSmallInteger('sort')->default(0);
            $t->timestamps();
        });

        Schema::create('item_histories', function (Blueprint $t) {
            $t->id();
            $t->foreignId('item_id')->constrained()->cascadeOnDelete();
            $t->string('from_status')->nullable();
            $t->string('to_status');
            $t->text('note')->nullable();
            $t->string('actor')->nullable();
            $t->timestamps();
        });

        Schema::create('purchase_orders', function (Blueprint $t) {
            $t->id();
            $t->foreignId('vendor_id')->constrained()->cascadeOnDelete();
            $t->string('draft_no')->unique();
            $t->string('wms_po_no')->nullable()->index();
            // draft | submitted | approved | exception
            $t->string('status')->default('draft')->index();
            $t->string('delivery_mode');                      // vendor | ebest | jit
            $t->string('vendor_name');                        // 供货商名称
            $t->date('purchase_date');
            $t->string('purchaser');
            $t->string('marketing_mode');
            $t->date('eta_date');
            $t->boolean('sync_stock')->default(true);
            $t->string('reference_no')->nullable();
            $t->text('note')->nullable();
            $t->text('exception_note')->nullable();
            $t->decimal('total', 12, 2)->default(0);
            $t->timestamp('submitted_at')->nullable();
            $t->timestamp('exported_at')->nullable();
            $t->timestamps();
        });

        Schema::create('purchase_order_lines', function (Blueprint $t) {
            $t->id();
            $t->foreignId('purchase_order_id')->constrained()->cascadeOnDelete();
            $t->foreignId('item_id')->nullable()->constrained()->nullOnDelete();
            $t->string('product_name');
            $t->string('sku_no')->nullable();
            $t->string('barcode')->nullable();
            $t->unsignedInteger('qty');
            $t->decimal('unit_price', 12, 4);                 // 含 GST
            $t->decimal('gst_rate', 5, 2)->default(10);
            $t->decimal('subtotal', 12, 2);
            $t->decimal('approved_qty', 12, 0)->nullable();   // 仓库审核数量
            $t->string('price_note')->nullable();             // 价格变动标注
            $t->string('pack_note')->nullable();              // 箱规说明
            $t->timestamps();
        });

        Schema::create('purchase_order_histories', function (Blueprint $t) {
            $t->id();
            $t->foreignId('purchase_order_id')->constrained()->cascadeOnDelete();
            $t->string('from_status')->nullable();
            $t->string('to_status');
            $t->text('note')->nullable();
            $t->string('actor')->nullable();
            $t->timestamps();
        });

        Schema::create('audit_logs', function (Blueprint $t) {
            $t->id();
            $t->string('actor');
            $t->string('action');
            $t->string('subject')->nullable();
            $t->text('detail')->nullable();
            $t->string('ip', 45)->nullable();
            $t->timestamps();
        });
    }

    public function down(): void
    {
        foreach (['audit_logs', 'purchase_order_histories', 'purchase_order_lines', 'purchase_orders', 'item_histories', 'item_images', 'items', 'vendor_histories', 'vendors', 'staff_users', 'sessions'] as $tbl) {
            Schema::dropIfExists($tbl);
        }
    }
};
