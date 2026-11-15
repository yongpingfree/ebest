# frozen_string_literal: true

require "rails_helper"

RSpec.describe "导出 Mailer order_by 清洗回归" do
  # 旧代码把 order_by 原样拼进 .order()，注入载荷在查询执行时会触发 PG::SyntaxError
  it "GiftCardMailer 注入载荷被清洗，导出正常完成" do
    expect {
      GiftCardMailer.coupons_export("ops@example.com", "1=1) asc; DROP TABLE magic_bean_gift_card_coupons;--", {})
    }.not_to raise_error
  end

  it "GiftCardMailer 合法排序照常生效" do
    expect {
      GiftCardMailer.coupons_export("ops@example.com", "created_at desc", {})
    }.not_to raise_error
  end

  it "PromoCodeMailer 注入载荷回退默认排序，导出正常完成" do
    expect {
      PromoCodeMailer.export("ops@example.com", "(SELECT 1) desc", {})
    }.not_to raise_error
  end

  it "PromoCodeMailer 合法排序照常生效" do
    expect {
      PromoCodeMailer.export("ops@example.com", "id asc", {})
    }.not_to raise_error
  end
end
