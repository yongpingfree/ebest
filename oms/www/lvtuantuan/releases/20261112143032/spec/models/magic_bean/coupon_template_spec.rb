# frozen_string_literal: true

require "rails_helper"

RSpec.describe MagicBean::CouponTemplate do
  describe ".batch_assign_coupons_via_csv_file" do
    let(:template) { MagicBean::CouponTemplate.new }
    let(:admin_user) { MagicBean::AdminUser.new(id: 1) }

    before do
      allow(MagicBean::CouponTemplate).to receive(:find_by).with(id: 1).and_return(template)
      allow(MagicBean::AdminUser).to receive(:find_by).with(id: 1).and_return(admin_user)
    end

    it "白名单外地址直接拒绝且不发起网络请求" do
      expect(URI).not_to receive(:open)
      expect {
        described_class.batch_assign_coupons_via_csv_file(1, "https://evil.com/mobiles.csv", 1)
      }.to raise_error(ArgumentError, /文件地址不受支持/)
    end

    it "file:// 路径拒绝" do
      expect(URI).not_to receive(:open)
      expect {
        described_class.batch_assign_coupons_via_csv_file(1, "file:///tmp/mobiles.csv", 1)
      }.to raise_error(ArgumentError, /文件地址不受支持/)
    end

    it "模板不存在时静默返回（既有行为）" do
      allow(MagicBean::CouponTemplate).to receive(:find_by).with(id: 2).and_return(nil)
      expect(URI).not_to receive(:open)
      expect(described_class.batch_assign_coupons_via_csv_file(2, "https://evil.com/mobiles.csv", 1)).to be_nil
    end
  end
end
