# frozen_string_literal: true

require "rails_helper"

RSpec.describe MagicBean::VerificationCode do
  # 随机 mobile 保证失败计数 key 不跨用例/跨运行残留
  let(:mobile) { "test_#{SecureRandom.hex(4)}" }

  describe "#verify" do
    it "真实短信码正确时返回 true" do
      vc = described_class.new(mobile, :login)
      vc.code = "654321"
      expect(vc.verify("654321")).to be(true)
    end

    it "错误码返回 false" do
      vc = described_class.new(mobile, :login)
      vc.code = "654321"
      expect(vc.verify("111111")).to be(false)
    end

    it "万能码仅在 development 环境生效" do
      allow(Rails.env).to receive(:development?).and_return(true)
      vc = described_class.new(mobile, :login)
      expect(vc.verify(described_class::DEVELOPMENT_TEST_VERIFICATION_CODE)).to be(true)
    end

    it "staging/生产环境万能码失效" do
      allow(Rails.env).to receive(:development?).and_return(false)
      allow(Rails.env).to receive(:production?).and_return(true)
      vc = described_class.new(mobile, :login)
      expect(vc.verify(described_class::DEVELOPMENT_TEST_VERIFICATION_CODE)).to be(false)
    end

    it "生产环境 12345678 尾号手机号不再放行万能码" do
      allow(Rails.env).to receive(:development?).and_return(false)
      allow(Rails.env).to receive(:production?).and_return(true)
      vc = described_class.new("0412345678", :login)
      expect(vc.verify(described_class::DEVELOPMENT_TEST_VERIFICATION_CODE)).to be(false)
    end

    it "一次性 universal code 验证成功后即销毁" do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      Rails.cache.write(described_class::UNIVERSAL_CODE_KEY, "95279527")
      vc = described_class.new(mobile, :login)
      expect(vc.verify("95279527")).to be(true)
      expect(vc.verify("95279527")).to be(false)
    end

    describe "失败次数限制" do
      it "失败计入计数" do
        vc = described_class.new(mobile, :login)
        vc.code = "654321"
        expect(vc.verify("000000")).to be(false)
        expect(vc.failed_attempts.value).to eq(1)
      end

      it "达到上限后窗口内拒绝一切验证码（含正确码）" do
        vc = described_class.new(mobile, :login)
        vc.code = "654321"
        described_class::MAX_VERIFY_ATTEMPTS.times { vc.verify("000000") }
        expect(vc.verify("654321")).to be(false)
      end

      it "验证成功后清零失败计数" do
        vc = described_class.new(mobile, :login)
        vc.code = "654321"
        3.times { vc.verify("000000") }
        expect(vc.verify("654321")).to be(true)
        expect(vc.failed_attempts.value).to eq(0)
      end

      it "计数按 mobile+event 隔离" do
        vc_a = described_class.new(mobile, :login)
        vc_a.code = "654321"
        vc_a.verify("000000")
        vc_b = described_class.new(mobile, :reset_password)
        vc_b.code = "654321"
        expect(vc_b.verify("654321")).to be(true)
      end
    end
  end
end
