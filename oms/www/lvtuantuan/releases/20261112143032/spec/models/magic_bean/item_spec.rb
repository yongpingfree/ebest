# frozen_string_literal: true

require "rails_helper"

RSpec.describe MagicBean::Item, type: :model do
  describe "#update item attribute after sku commit" do
    let(:item) { create(:item) }

    context "when item and sku created" do
      it "update attributes" do
        on_sale_skus = item.stock_keeping_units.select { |sku| sku.on_sale? }.compact
        expect(item.quantity).to eq(on_sale_skus.map(&:quantity).sum)
        expect(item.price_in_cent).to eq(on_sale_skus.map(&:price_in_cent).min.to_i)
        expect(item.strikethrough_price_in_cent).to eq(on_sale_skus.map(&:strikethrough_price_in_cent).min)
      end
    end

    context "when sku updated" do

      before do
        item.stock_keeping_units.first.update(
          quantity: 2,
          price_in_cent: 2,
          strikethrough_price_in_cent: 3
        )
      end

      it "also update attributes" do
        on_sale_skus = item.stock_keeping_units.select { |sku| sku.on_sale? }.compact
        expect(item.quantity).to eq(on_sale_skus.map(&:quantity).sum)
        expect(item.price_in_cent).to eq(on_sale_skus.map(&:price_in_cent).min.to_i)
        expect(item.strikethrough_price_in_cent).to eq(on_sale_skus.map(&:strikethrough_price_in_cent).min)
      end
    end
  end
end
