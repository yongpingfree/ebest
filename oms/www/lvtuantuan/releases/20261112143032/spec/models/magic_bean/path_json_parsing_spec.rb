# frozen_string_literal: true

require "rails_helper"

RSpec.describe "path 字段 JSON 解析（eval → JSON.parse，消除存储型 RCE）" do
  %w[PagePopup ItemBanner MinePageActivitySetting].each do |class_name|
    model = "MagicBean::#{class_name}".constantize

    describe "#{model}#path_name" do
      it "返回 JSON 的 name 字段" do
        record = model.new(path: '{"link":"/pages/index","name":"首页"}')
        expect(record.path_name).to eq("首页")
      end

      it "JSON 无 name 字段时返回 nil" do
        record = model.new(path: '{"link":"/pages/index"}')
        expect(record.path_name).to be_nil
      end

      it "非 JSON 内容返回 nil 而不是执行" do
        record = model.new(path: 'system("echo hacked"); { name: "x" }')
        expect(record.path_name).to be_nil
      end

      it "path 为空返回 nil" do
        expect(model.new(path: "").path_name).to be_nil
        expect(model.new(path: nil).path_name).to be_nil
      end
    end

    entity = "BeansApp::API::Entities::#{class_name}".constantize

    describe "#{entity}#format_path" do
      it "返回解析后的 JSON（字符串键）" do
        record = model.new(path: '{"link":"/pages/index"}')
        expect(entity.new(record).format_path).to eq("link" => "/pages/index")
      end

      it "非 JSON 内容返回 nil 而不是执行" do
        record = model.new(path: 'system("echo hacked"); { link: "/x" }')
        expect(entity.new(record).format_path).to be_nil
      end

      it "path 为空返回 nil" do
        expect(entity.new(model.new(path: "")).format_path).to be_nil
        expect(entity.new(model.new(path: nil)).format_path).to be_nil
      end
    end
  end
end
