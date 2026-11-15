# frozen_string_literal: true

module PriceConvertConcern
  extend ActiveSupport::Concern

  class_methods do
    def convert_price_to_yuan(*price_attrs)
      postfix = "in_yuan"

      price_attrs.map(&:to_s).each do |price_attr|
        if price_attr.end_with? "in_cent"
          price_in_yuan = price_attr.gsub(/in_cent$/, postfix)
        else
          price_in_yuan = [price_attr, postfix].join("_")
        end

        define_method price_in_yuan do
          value = send(price_attr)
          ActiveSupport::NumberHelper.number_to_currency(value.to_i / 100.0, format: "%n", delimiter: "") if value.present?
        end

        define_singleton_method "#{price_in_yuan}_sum" do
          ActiveSupport::NumberHelper.number_to_currency(sum(price_attr).to_i / 100.0, format: "%n", delimiter: "")
        end

        define_method "#{price_in_yuan}=" do |value|
          value = value.present? ? (value.to_f * 100).round : nil
          write_attribute(price_attr, value)
        end

        define_method "#{price_in_yuan}_num" do
          send(price_attr).to_f / 100.0
        end
      end
    end
  end
end
