# frozen_string_literal: true

require "aws-sdk-sns"

module Aws
  class SMS
    DEFAULT_SMS_TYPE = "Transactional"
    PROMOTIONAL_SMS_TYPE = "Promotional"

    class << self
      # sms_type: 覆盖配置的短信类型, 营销短信传 "Promotional"
      def send_message(phone, message, sms_type = nil)
        response = client.publish(
          phone_number: normalize_australian_phone(phone),
          message: message.to_s,
          message_attributes: message_attributes(sms_type)
        )

        logger.info("AWS SMS sent: message_id=#{response.message_id}, phone=#{mask_phone(phone)}")
        response
      rescue Aws::Errors::ServiceError, Seahorse::Client::NetworkingError => e
        logger.error("AWS SMS send failed: phone=#{mask_phone(phone)}, error=#{e.class}: #{e.message}")
        raise
      end

      private

      # 营销短信(Promotional)使用独立的 promotional_sender_id, 其余走 sms_sender_id
      def sender_id_for(sms_type)
        if sms_type == PROMOTIONAL_SMS_TYPE
          config_value(:promotional_sender_id)
        else
          config_value(:sms_sender_id)
        end
      end

      def client
        @client ||= Aws::SNS::Client.new(client_options)
      end

      def client_options
        options = {}
        options[:region] = config_value(:region) if config_value(:region).present?
        access_key_id = config_value(:sms_access_key_id)
        secret_access_key = config_value(:sms_secret_access_key)
        if access_key_id.present? && secret_access_key.present?
          options[:credentials] = Aws::Credentials.new(access_key_id, secret_access_key)
        end
        options
      end

      # 业务上只发澳洲号码,统一补 +61;顺带清洗空格等非数字字符以满足 SNS 的 E.164 要求
      def normalize_australian_phone(phone)
        digits = phone.to_s.gsub(/\D/, "")
        raise ArgumentError, "phone is blank" if digits.blank?

        if digits.start_with?("61")
          "+#{digits}"
        elsif digits.start_with?("0")
          "+61#{digits.sub(/\A0/, '')}"
        else
          "+61#{digits}"
        end
      end

      def message_attributes(sms_type = nil)
        attributes = {
          "AWS.SNS.SMS.SMSType" => string_attribute(sms_type.presence || config_value(:sms_type) || DEFAULT_SMS_TYPE)
        }

        sender_id = sender_id_for(sms_type)
        attributes["AWS.SNS.SMS.SenderID"] = string_attribute(sender_id) if sender_id.present?

        origination_number = config_value(:origination_number)
        attributes["AWS.MM.SMS.OriginationNumber"] = string_attribute(origination_number) if origination_number.present?

        max_price = config_value(:max_price)
        attributes["AWS.SNS.SMS.MaxPrice"] = string_attribute(max_price) if max_price.present?

        attributes
      end

      def string_attribute(value)
        {
          data_type: "String",
          string_value: value.to_s
        }
      end

      # 短信相关配置平级放在 credentials 的 aws 段下,如 sms_send_id
      def config
        @config ||= Rails.application.credentials.dig(Rails.env.to_sym, :aws) || {}
      end

      def config_value(key)
        config[key] || config[key.to_s]
      end

      def mask_phone(phone)
        digits = phone.to_s.gsub(/\D/, "")
        return "" if digits.blank?

        "#{digits[0, 3]}****#{digits[-3, 3]}"
      end

      def logger
        @logger ||= Logger.new(Rails.root.join("log", "aws_sms.log"))
      end
    end
  end
end
