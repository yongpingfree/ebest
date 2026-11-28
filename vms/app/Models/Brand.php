<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Brand extends Model
{
    protected $guarded = ['id'];

    protected function casts(): array
    {
        return ['ebest_brand_id_at' => 'datetime'];
    }

    public function vendor(): BelongsTo
    {
        return $this->belongsTo(Vendor::class);
    }

    /** 页面显示用地址:本地盘按当前域名生成,S3 用保存的 CDN 地址 */
    public function getDisplayUrlAttribute(): string
    {
        if (! $this->image_path) {
            return '';
        }
        if (config('vms.image_disk') === 'public') {
            return url('/vms/storage/'.$this->image_path);
        }

        return (string) $this->image_url;
    }

    /** 下拉显示「id-名称」:已有 eBest 品牌 id 用该 id,否则用 VMS 编号(前缀 V) */
    public function label(): string
    {
        $id = $this->ebest_brand_id ?: 'V'.$this->id;
        $name = app()->getLocale() === 'en' && $this->name_en ? $this->name_en : $this->name;

        return $id.'-'.$name;
    }
}
