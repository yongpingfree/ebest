<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class VendorHistory extends Model
{
    protected $guarded = ['id'];

    protected $casts = ['snapshot' => 'array'];
}
