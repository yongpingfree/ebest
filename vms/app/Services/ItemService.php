<?php

namespace App\Services;

use App\Models\Item;
use App\Models\Vendor;
use Illuminate\Validation\Rule;

class ItemService
{
    /** @return array<int,array> */
    public static function fields(?string $scope = null): array
    {
        $all = config('vms.item_fields');

        return $scope ? array_values(array_filter($all, fn ($f) => $f['scope'] === $scope)) : $all;
    }

    public static function defaults(): array
    {
        $d = [];
        foreach (self::fields() as $f) {
            if (isset($f['default'])) {
                $d[$f['key']] = $f['default'];
            }
        }

        return $d;
    }

    /** 从请求中取出某个 scope 的字段值(多选字段用分号连接) */
    public static function extract(array $input, string $scope): array
    {
        $out = [];
        foreach (self::fields($scope) as $f) {
            $v = $input[$f['key']] ?? null;
            if (is_array($v)) {
                $v = implode(';', array_filter($v));
            }
            $out[$f['key']] = ($v === null || $v === '') ? null : trim((string) $v);
        }

        return $out;
    }

    /** 保存草稿的校验:只强制商品编码和中文标题,其余字段做格式校验 */
    public static function draftRules(Vendor $vendor, ?Item $item): array
    {
        $rules = [
            'title_zh_cn' => ['required', 'string', 'max:255'],
            'sku_no' => ['required', 'string', 'max:64', Rule::unique('items', 'sku_no')->where('vendor_id', $vendor->id)->ignore($item?->id)],
        ];
        foreach (self::fields('vendor') as $f) {
            if (isset($rules[$f['key']])) {
                continue;
            }
            $r = ['nullable'];
            // 注意:数组形式的规则里不能使用 'a|b' 写法,必须拆成独立元素
            $r = array_merge($r, match ($f['type']) {
                'number' => ['integer', 'min:0'],
                'decimal' => ['numeric', 'min:0'],
                'textarea' => ['string', 'max:5000'],
                'select', 'yesno' => [Rule::in($f['options'])],
                'multi' => ['array'],
                default => ['string', 'max:255'],
            });
            $rules[$f['key']] = $r;
            if ($f['type'] === 'multi') {
                $rules[$f['key'].'.*'] = [Rule::in($f['options'])];
            }
        }

        return $rules;
    }

    public static function attributeNames(): array
    {
        $n = [];
        foreach (self::fields() as $f) {
            $n[$f['key']] = $f['label'];
        }

        return $n;
    }

    /** 提交前检查必填项和图片,返回缺失项说明 */
    public static function missingForSubmit(Item $item): array
    {
        $errors = [];
        $data = $item->data ?? [];
        $virtual = ($data['is_virtual'] ?? '否') === '是';
        foreach (self::fields('vendor') as $f) {
            $k = $f['key'];
            $empty = ! isset($data[$k]) || $data[$k] === '';
            $needed = $f['required'];
            if (! $needed && isset($f['required_if'])) {
                foreach ($f['required_if'] as $depKey => $depVal) {
                    if (($data[$depKey] ?? null) === $depVal) {
                        $needed = true;
                    }
                }
            }
            if ($virtual && in_array($k, ['delivery_type'], true)) {
                $needed = false; // 虚拟产品无需填写配送方式
            }
            if ($needed && $empty) {
                $errors[] = "「{$f['label']}」为必填项";
            }
        }
        if (($data['price_in_yuan'] ?? 0) !== null && isset($data['price_in_yuan']) && (float) $data['price_in_yuan'] <= 0) {
            $errors[] = '「价格」必须大于 0';
        }
        $counts = $item->images->groupBy('kind')->map->count();
        foreach (config('vms.image_kinds') as $kind => $spec) {
            if ($spec['required'] && ! ($counts[$kind] ?? 0)) {
                $errors[] = "请上传「{$spec['label']}」({$spec['hint']})";
            }
        }
        if ($item->vendor && ! $item->vendor->isApproved()) {
            $errors[] = '供应商资料尚未审核通过,不能提交商品';
        }

        return $errors;
    }
}
