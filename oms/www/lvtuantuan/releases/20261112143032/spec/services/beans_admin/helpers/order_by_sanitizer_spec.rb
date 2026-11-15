# frozen_string_literal: true

require "rails_helper"

RSpec.describe BeansAdmin::Helpers::OrderBySanitizer do
  describe ".sanitize_fragments" do
    it "保留合法片段（列 + 方向，大小写不敏感）" do
      expect(described_class.sanitize_fragments("created_at desc, payment_time ASC")).to eq(
        ["created_at desc", "payment_time ASC"]
      )
    end

    it "保留带关联前缀的片段" do
      expect(described_class.sanitize_fragments("orders.id desc")).to eq(["orders.id desc"])
    end

    it "保留含数字的列名" do
      expect(described_class.sanitize_fragments("total_2 desc")).to eq(["total_2 desc"])
    end

    it "丢弃 SQL 注入片段" do
      malicious = "created_at desc; DROP TABLE users;--"
      expect(described_class.sanitize_fragments(malicious)).to be_empty
    end

    it "丢弃子查询/函数/注释等片段" do
      payloads = [
        "(SELECT 1) desc",
        "created_at, (SELECT password FROM admin_users) desc",
        "id desc --",
        "1=1) asc",
        "sleep(5) desc"
      ]
      payloads.each do |payload|
        expect(described_class.sanitize_fragments(payload)).to be_empty
      end
    end

    it "丢弃缺方向的裸列名" do
      expect(described_class.sanitize_fragments("created_at")).to be_empty
    end

    it "nil 返回空数组" do
      expect(described_class.sanitize_fragments(nil)).to eq([])
    end

    it "前后空白与空片段被剔除" do
      expect(described_class.sanitize_fragments("  created_at desc , ,,id asc")).to eq(
        ["created_at desc", "id asc"]
      )
    end
  end

  describe ".sanitize" do
    it "合法值原样保留（逗号串）" do
      expect(described_class.sanitize("created_at desc, id asc")).to eq("created_at desc, id asc")
    end

    it "默认排序片段可通过校验" do
      expect(described_class.sanitize("created_at DESC")).to eq("created_at DESC")
      expect(described_class.sanitize("orders.id desc")).to eq("orders.id desc")
    end

    it "全部非法时返回空串（调用方据此回退默认排序）" do
      expect(described_class.sanitize("1=1) asc; --")).to eq("")
      expect(described_class.sanitize("")).to eq("")
      expect(described_class.sanitize(nil)).to eq("")
    end
  end
end
