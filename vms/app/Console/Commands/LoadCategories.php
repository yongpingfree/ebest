<?php

namespace App\Console\Commands;

use App\Models\Category;
use Illuminate\Console\Command;

class LoadCategories extends Command
{
    protected $signature = 'vms:load-categories {file? : CSV 路径,默认 storage/app/categories/categories.csv} {--prune : 删除 CSV 中不存在的分类}';

    protected $description = '把从 OMS 导出的分类和子分类 CSV(id,parent_id,name_zh,name_en,status,position)载入 VMS 分类表';

    public function handle(): int
    {
        $path = $this->argument('file') ?: storage_path('app/categories/categories.csv');
        if (! is_readable($path)) {
            $this->error("找不到文件:$path(用 database/oms/export_categories.sql 在 OMS 导出)");

            return self::FAILURE;
        }
        $f = fopen($path, 'r');
        $head = fgetcsv($f);
        if ($head && isset($head[0])) {
            $head[0] = ltrim($head[0], "\xEF\xBB\xBF"); // 去掉 BOM
        }
        $head = array_map(fn ($h) => strtolower(trim((string) $h)), (array) $head);
        foreach (['id', 'parent_id', 'name_zh'] as $need) {
            if (! in_array($need, $head, true)) {
                $this->error("CSV 缺少列:$need");

                return self::FAILURE;
            }
        }
        $now = now();
        $rows = [];
        $seen = [];
        while (($line = fgetcsv($f)) !== false) {
            if (count($line) < count($head)) {
                continue;
            }
            $r = array_combine($head, array_slice($line, 0, count($head)));
            if (! ctype_digit(trim((string) $r['id']))) {
                continue;
            }
            $id = (int) $r['id'];
            $seen[] = $id;
            $rows[] = [
                'id' => $id,
                'parent_id' => ($r['parent_id'] ?? '') !== '' && ctype_digit(trim($r['parent_id'])) ? (int) $r['parent_id'] : null,
                'name_zh' => $r['name_zh'] !== '' ? $r['name_zh'] : null,
                'name_en' => ($r['name_en'] ?? '') !== '' ? $r['name_en'] : null,
                'status' => ($r['status'] ?? '') !== '' ? (int) $r['status'] : 1,
                'position' => ($r['position'] ?? '') !== '' ? (int) $r['position'] : 0,
                'created_at' => $now, 'updated_at' => $now,
            ];
        }
        fclose($f);
        if (! $rows) {
            $this->error('CSV 中没有有效数据');

            return self::FAILURE;
        }
        foreach (array_chunk($rows, 500) as $chunk) {
            Category::upsert($chunk, ['id'], ['parent_id', 'name_zh', 'name_en', 'status', 'position', 'updated_at']);
        }
        if ($this->option('prune')) {
            $this->info('已删除 '.Category::whereNotIn('id', $seen)->delete().' 条不在 CSV 中的分类');
        }
        $top = count(array_filter($rows, fn ($r) => $r['parent_id'] === null));
        $this->info('已载入 '.count($rows)." 条分类(其中一级分类 $top 条)");

        return self::SUCCESS;
    }
}
