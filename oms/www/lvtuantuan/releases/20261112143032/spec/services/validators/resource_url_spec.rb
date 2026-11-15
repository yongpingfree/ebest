# frozen_string_literal: true

require "rails_helper"

RSpec.describe Validators::ResourceUrl do
  describe ".valid?" do
    it "白名单 host 通过" do
      expect(described_class.valid?("https://cdn.minimall.donkibuy.com/items/a.jpg")).to be(true)
      expect(described_class.valid?("https://lvtuantuan-staging.oss-ap-southeast-2.aliyuncs.com/images/a.jpg")).to be(true)
      expect(described_class.valid?("https://lvtuantuan-staging.s3.ap-southeast-2.amazonaws.com/items/a.jpg")).to be(true)
    end

    it "白名单外 host 拒绝（含内网地址）" do
      expect(described_class.valid?("https://evil.com/a.jpg")).to be(false)
      expect(described_class.valid?("http://169.254.169.254/latest/meta-data/")).to be(false)
      expect(described_class.valid?("http://127.0.0.1:5432/")).to be(false)
    end

    it "host 大小写不敏感" do
      expect(described_class.valid?("https://CDN.MINIMALL.DONKIBUY.COM/items/a.jpg")).to be(true)
    end

    it "nil 和空串放行，空数组放行" do
      expect(described_class.valid?(nil)).to be(true)
      expect(described_class.valid?("")).to be(true)
      expect(described_class.valid?([])).to be(true)
    end

    it "数组全量校验，一个非法即拒绝" do
      expect(described_class.valid?(["https://cdn.minimall.donkibuy.com/a.jpg", "https://evil.com/b.jpg"])).to be(false)
      expect(described_class.valid?(["https://cdn.minimall.donkibuy.com/a.jpg", ""])).to be(true)
    end

    it "URI 解析失败视为无效" do
      expect(described_class.valid?("http://[invalid")).to be(false)
    end

    it "userinfo 伪装 host 无法绕过" do
      expect(described_class.valid?("https://cdn.minimall.donkibuy.com@evil.com/a.jpg")).to be(false)
    end
  end

  describe ".valid_file_url?" do
    it "白名单存储 host 通过（含 prod S3 直连域）" do
      expect(described_class.valid_file_url?("https://ebest-production.s3.ap-southeast-2.amazonaws.com/coupon_templates/a.csv")).to be(true)
      expect(described_class.valid_file_url?("https://lvtuantuan-staging.s3.ap-southeast-2.amazonaws.com/items/a.xlsx")).to be(true)
      expect(described_class.valid_file_url?("https://cdn.minimall.donkibuy.com/import/a.xlsx")).to be(true)
      expect(described_class.valid_file_url?("https://lvtuantuan-staging.oss-ap-southeast-2.aliyuncs.com/a.xlsx")).to be(true)
    end

    it "白名单外 host 拒绝（含内网地址）" do
      expect(described_class.valid_file_url?("https://evil.com/a.csv")).to be(false)
      expect(described_class.valid_file_url?("http://169.254.169.254/latest/meta-data/a.csv")).to be(false)
      expect(described_class.valid_file_url?("http://127.0.0.1:4567/a.xlsx")).to be(false)
    end

    it "file:// 与相对路径拒绝（无 host）" do
      expect(described_class.valid_file_url?("file:///etc/passwd")).to be(false)
      expect(described_class.valid_file_url?("uploads/a.csv")).to be(false)
    end

    it "blank 不放行（导入必须给地址，与图片校验不同）" do
      expect(described_class.valid_file_url?(nil)).to be(false)
      expect(described_class.valid_file_url?("")).to be(false)
    end

    it "userinfo 伪装 host 无法绕过" do
      expect(described_class.valid_file_url?("https://ebest-production.s3.ap-southeast-2.amazonaws.com@evil.com/a.csv")).to be(false)
    end
  end

  describe "#validate_param!" do
    let(:scope) { double("scope", full_name: "main_images") }
    let(:validator) { described_class.new(:main_images, {}, false, scope) }

    it "全 blank 参数不报错" do
      expect do
        validator.validate_param!(:main_images, main_images: [""])
      end.not_to raise_error
    end

    it "白名单内参数不报错" do
      expect do
        validator.validate_param!(:main_images, main_images: ["https://cdn.minimall.donkibuy.com/a.jpg"])
      end.not_to raise_error
    end

    it "白名单外参数报无效链接" do
      expect do
        validator.validate_param!(:main_images, main_images: ["https://evil.com/a.jpg"])
      end.to raise_error(Grape::Exceptions::Validation, /无效链接/)
    end
  end
end
