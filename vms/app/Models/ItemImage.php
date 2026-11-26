<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ItemImage extends Model
{
    protected $guarded = ['id'];

    /** 页面显示用地址:本地盘按当前访问域名生成(不依赖 APP_URL),S3 用保存的 CDN 地址 */
    public function getDisplayUrlAttribute(): string
    {
        if (config('vms.image_disk') === 'public') {
            return url('/vms/storage/'.$this->path);
        }

        return (string) $this->url;
    }
}
