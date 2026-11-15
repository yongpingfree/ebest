# frozen_string_literal: true

require "rails_helper"

RSpec.describe GenerateAwsLambdaImageJob do
  describe "#touch_aws_image_lambda" do
    let(:job) { described_class.new }

    it "白名单 URL 发起拉取" do
      allow(RestClient).to receive(:get).and_return(double("response"))
      expect(job.touch_aws_image_lambda("https://cdn.minimall.donkibuy.com/items/a.jpg")).to be(true)
      expect(RestClient).to have_received(:get).with("https://cdn.minimall.donkibuy.com/items/a.jpg")
    end

    it "白名单外 URL 不发起任何请求（SSRF 防护）" do
      allow(RestClient).to receive(:get)
      expect(job.touch_aws_image_lambda("https://evil.com/a.jpg")).to be(false)
      expect(job.touch_aws_image_lambda("http://169.254.169.254/latest/meta-data/")).to be(false)
      expect(RestClient).not_to have_received(:get)
    end

    it "空 URL 直接视为成功" do
      allow(RestClient).to receive(:get)
      expect(job.touch_aws_image_lambda("")).to be(true)
      expect(RestClient).not_to have_received(:get)
    end

    it "占位图直接跳过" do
      expect(job.touch_aws_image_lambda("https://cdn.minimall.donkibuy.com/items/zhanweitu.png")).to be(false)
    end
  end
end
