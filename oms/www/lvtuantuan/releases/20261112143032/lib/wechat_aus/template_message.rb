# frozen_string_literal: true

module WechatAus
  class TemplateMessage

    @@templates = YAML.load(File.read("#{Rails.root}/config/templates_aus.yml"))[Rails.env]

    def self.get_templates
      @@templates
    end

    @@templates.each do |key, value|
      define_singleton_method key do
        value
      end
    end

    def self.get_template_id(name)
      @@templates[name]
    end

    def self.data_formater(data)
      data.each do |k, v|
        v[:value] = data_format(k.to_s, v[:value])
      end
    end

    def self.data_format(type, data)
      if type.start_with?("thing", "name")
        # name 10个以内纯汉字或20个以内纯字母或符号
        data&.truncate(20)
      elsif type.start_with?("letter", "character_string")
        data&.truncate(32)
      elsif type.start_with?("symbol")
        data&.truncate(5)
      elsif type.start_with?("phone_number")
        data&.truncate(17)
      elsif type.start_with?("car_number")
        data&.truncate(8)
      elsif type.start_with?("phrase")
        data&.truncate(5)
      else
        # 由于job不能接收time类型参数，所以time和date类型数据需提前格式化：strftime("%Y年%m月%d日 %H:%M")
        data
      end
    end
  end
end
