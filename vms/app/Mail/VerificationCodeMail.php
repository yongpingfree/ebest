<?php

namespace App\Mail;

use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;

class VerificationCodeMail extends Mailable
{
    public function __construct(public string $code, public int $minutes) {}

    public function envelope(): Envelope
    {
        return new Envelope(subject: 'eBest 供应商门户邮箱验证码');
    }

    public function content(): Content
    {
        return new Content(htmlString: "<p>您好,</p><p>您的 eBest 供应商门户邮箱验证码是:<b style=\"font-size:22px;letter-spacing:4px\">{$this->code}</b></p><p>验证码 {$this->minutes} 分钟内有效。如非本人操作请忽略此邮件。</p>");
    }
}
