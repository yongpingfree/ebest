# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResourceUrlValidationConcern do
  describe "白名单校验" do
    it "图片列变更时白名单外 URL 报无效链接" do
      category = build(:category, icon: "https://evil.com/icon.png")
      category.valid?
      expect(category.errors[:icon]).to include("无效链接")
    end

    it "白名单内 URL 通过" do
      category = build(:category, icon: "https://cdn.minimall.donkibuy.com/items/icon.png")
      category.valid?
      expect(category.errors[:icon]).to be_empty
    end

    it "nil 和空串放行" do
      category = build(:category, icon: nil, filter_icon: "")
      category.valid?
      expect(category.errors[:icon]).to be_empty
      expect(category.errors[:filter_icon]).to be_empty
    end

    it "数组内一个非法 URL 即报错（含内网地址）" do
      item = build(:item, ae_drop_shipper: false, main_images: ["https://cdn.minimall.donkibuy.com/a.jpg", "http://169.254.169.254/latest/meta-data/"])
      item.valid?
      expect(item.errors[:main_images]).to include("无效链接")
    end

    it "图片列未变更时不触发校验" do
      category = create(:category, icon: "https://cdn.minimall.donkibuy.com/items/icon.png")
      category.name_zh_cn = "改名"
      expect(category).to be_valid
    end
  end

  describe "ae_drop_shipper 豁免" do
    it "跨境购 item 允许速卖通 CDN 图片" do
      item = build(:item, ae_drop_shipper: true, main_images: ["https://ae01.alicdn.com/img/a.jpg"])
      item.valid?
      expect(item.errors[:main_images]).to be_empty
    end

    it "跨境购 SKU 允许速卖通 CDN 图片（ae_drop_shipper 委托自 item）" do
      item = create(:item, ae_drop_shipper: true)
      sku = build(:stock_keeping_unit, item: item, image: "https://ae01.alicdn.com/img/b.jpg")
      sku.valid?
      expect(sku.errors[:image]).to be_empty
    end

    it "非跨境购 item 的速卖通 CDN 图片被拒绝" do
      item = build(:item, ae_drop_shipper: false, main_images: ["https://ae01.alicdn.com/img/a.jpg"])
      item.valid?
      expect(item.errors[:main_images]).to include("无效链接")
    end

    it "孤儿 SKU（item 缺失）豁免判断不抛委托错误" do
      # 完整 valid? 会先被既有的 set_default_value（item.store_id）拦住，
      # 这里只验证新增代码自身的 nil 安全（方法在模型里是 private，用 send 调）
      sku = build(:stock_keeping_unit, item: nil, properties: nil)
      expect { sku.send(:resource_url_validation_enabled?) }.not_to raise_error
      expect(sku.send(:resource_url_validation_enabled?)).to be true
    end
  end
end
