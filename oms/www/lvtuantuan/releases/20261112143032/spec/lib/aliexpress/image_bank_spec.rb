# frozen_string_literal: true

require "rails_helper"

RSpec.describe Aliexpress::ImageBank do
  describe ".build" do
    it "白名单外 URL 不做任何拉取与处理（SSRF 防护）" do
      allow(MiniMagick::Image).to receive(:open)
      expect(described_class.build("https://evil.com/a.jpg")).to be_nil
      expect(MiniMagick::Image).not_to have_received(:open)
    end

    it "白名单 URL 进入图片处理流程" do
      allow(MiniMagick::Image).to receive(:open).and_raise("reached MiniMagick")
      expect(described_class.build("https://cdn.minimall.donkibuy.com/items/a.jpg")).to be_nil
      expect(MiniMagick::Image).to have_received(:open).with("https://cdn.minimall.donkibuy.com/items/a.jpg")
    end
  end
end
