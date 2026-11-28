<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Category extends Model
{
    public $incrementing = false;

    protected $guarded = [];

    public function label(): string
    {
        $name = app()->getLocale() === 'en' && $this->name_en ? $this->name_en : ($this->name_zh ?: $this->name_en);

        return $this->id.'-'.$name;
    }

    /** @return array{0: \Illuminate\Support\Collection, 1: array<int,array<int,array{id:int,label:string}>>} 一级分类与按父 id 分组的子分类 */
    public static function tree(): array
    {
        $all = static::where('status', 1)->orderBy('position')->orderBy('id')->get();
        $parents = $all->whereNull('parent_id')->values();
        $children = [];
        foreach ($all->whereNotNull('parent_id') as $c) {
            $children[$c->parent_id][] = ['id' => $c->id, 'label' => $c->label()];
        }

        return [$parents, $children];
    }
}
