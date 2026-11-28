<?php

namespace App\Mail;

use App\Models\Vendor;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;

/** 供应商提交注册资料(或资料修改)后通知 eBest 员工审核。员工端固定中文,不走翻译 */
class VendorSubmittedMail extends Mailable
{
    public function __construct(public Vendor $vendor, public bool $amend) {}

    public function envelope(): Envelope
    {
        $what = $this->amend ? '资料修改申请' : '新供应商注册';

        return new Envelope(subject: "[VMS] {$what}待审核:".($this->vendor->name ?: $this->vendor->email));
    }

    public function content(): Content
    {
        $v = $this->vendor;
        $link = url('/vms/staff/vendors/'.$v->id);
        $brands = $v->brands()->get()->map(fn ($b) => $b->name)->implode('、');
        $what = $this->amend ? '提交了资料修改申请' : '完成了注册并提交了资料';
        $html = '<p>您好,</p>'
            .'<p>供应商 <b>'.e($v->name ?: $v->email).'</b>('.e($v->email).')'.$what.',请审核。</p>'
            .'<ul><li>ABN:'.e((string) $v->abn).'</li><li>品牌:'.e($brands ?: '—').'</li></ul>'
            .'<p><a href="'.e($link).'">打开审核页面</a></p>'
            .'<p>通过后请在 WMS 建立供应商和品牌,并在 VMS 回填对应编号。</p>';

        return new Content(htmlString: $html);
    }
}
