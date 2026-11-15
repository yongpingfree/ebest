# frozen_string_literal: true

class MagicBean::Order
  # Klaviyo Email 相关
  module KlaviyoEmail
    extend ActiveSupport::Concern

    def enqueue_send_klaviyo_email_job(method)
      SendKlaviyoEmailJob.perform_later(self.class.model_name.name, id, method)
    end

    def send_order_paid_email
      KlaviyoAPI::Events.create_event(klaviyo_paid_order_event_body)
    end

    def send_order_fulfilled_email
      KlaviyoAPI::Events.create_event(klaviyo_fulfilled_order_event_body)
    end

    def send_order_sellout_refunded_email
      KlaviyoAPI::Events.create_event(klaviyo_sellout_refunded_order_event_body)
    end

    # doc: https://developers.klaviyo.com/en/reference/create_event
    def klaviyo_paid_order_event_body
      member = user.member
      I18n.with_locale(user_locale) do
        {
          "data": {
            "type": "event",
            "attributes": {
              "profile": {
                "data": {
                  "type": "profile",
                  "attributes": {
                    "email": member.email,
                    "first_name": member.first_name,
                    "last_name": member.last_name,
                    "phone_number": "+#{member.mobile}",
                  }
                }
              },
              "metric": {
                "data": {
                  "type": "metric",
                  "attributes": {
                    "name": "Paid Order"
                  }
                }
              },
              "properties": BeansApp::API::Entities::Order.represent(self).as_json,
              "time": paid_at,
              "value":  final_amount_in_yuan.to_f,
              "unique_id": no
            }
          }
        }
      end
    end

    def klaviyo_fulfilled_order_event_body
      member = user.member
      time = Time.current
      I18n.with_locale(user_locale) do
        {
          "data": {
            "type": "event",
            "attributes": {
              "profile": {
                "$email": member.email,
                "$first_name": member.first_name,
                "$last_name": member.last_name,
                "$phone_number": member.mobile,
              },
              "metric": {
                "name": "Fulfilled Order"
              },
              "properties": BeansApp::API::Entities::Order.represent(self).as_json,
              "time": time,
              "value":  final_amount_in_yuan.to_f,
              "unique_id": "#{no}-#{time.strftime('%Y-%m-%d')}"
            }
          }
        }
      end
    end

    def klaviyo_sellout_refunded_order_event_body
      member = user.member
      I18n.with_locale(user_locale) do
        {
          "data": {
            "type": "event",
            "attributes": {
              "profile": {
                "$email": member.email,
                "$first_name": member.first_name,
                "$last_name": member.last_name,
                "$phone_number": member.mobile,
              },
              "metric": {
                "name": "Refunded Order" # 整单缺货退款
              },
              "properties": BeansApp::API::Entities::Order.represent(self).as_json,
              "time": Time.current,
              "value":  final_amount_in_yuan.to_f,
              "unique_id": no
            }
          }
        }
      end
    end
  end
end
