# frozen_string_literal: true

module BeansAdmin
  class API::V1::PaymentSettings < ::API

    namespace :payment_settings, desc: "支付配置接口" do
      helpers do
        def permitted_params
          [
            :wechat_service_percentage,
            :vm_credit_card_service_percentage,
            :amex_credit_card_service_percentage,
            :unionpay_credit_card_service_percentage,
            :exchange_rate_rise_percentage,
            :omipay_wechat_service_percentage,
            :omipay_alipay_service_percentage,
            :supay_wechat_service_percentage,
            :supay_alipay_service_percentage,
            :enable_commweb_3ds_auth,
            :apple_pay_service_percentage,
            :cba_apple_pay_service_percentage,
            :cba_google_pay_service_percentage,
            :stripe_credit_card_service_percentage,
            :stripe_apple_pay_service_percentage,
            :stripe_google_pay_service_percentage,
            :no_transaction_fee_over_amount_in_yuan,
            :display_cba_credit_card_service,
            :display_unionpay_credit_card_service,
            :display_omipay_wechat_service,
            :display_omipay_alipay_service,
            :display_supay_wechat_service,
            :display_supay_alipay_service,
            :display_apple_pay_service,
            :display_cba_apple_pay_service,
            :display_cba_google_pay_service,
            :display_stripe_credit_card_service,
            :display_stripe_apple_pay_service,
            :display_stripe_google_pay_service
          ]
        end

        def resource
          if current_store_id.present?
            @resource ||= MagicBean::PaymentSetting.find_by(store_id: current_store_id)
          end
        end
      end

      desc "支付配置详情", {
        success: API::Entities::PaymentSetting
      }
      get do
        authorize_and_response_resource
      end

      route_param :id do
        desc "支付配置详情", {
          success: API::Entities::PaymentSetting
        }
        get do
          authorize_and_response_resource
        end

        desc "支付更新配置", {
          success: API::Entities::PaymentSetting
        }
        put do
          # TODO: 修改日志
          log_messages = []

          log_messages << "将小程序微信手续费百分百从#{resource.wechat_service_percentage}改为#{params[:wechat_service_percentage]}" if params[:wechat_service_percentage].present? && resource.wechat_service_percentage.to_f != params[:wechat_service_percentage].to_f
          log_messages << "将Omipay微信手续费百分比从#{resource.omipay_wechat_service_percentage}改为#{params[:omipay_wechat_service_percentage]}" if params[:omipay_wechat_service_percentage].present? && resource.omipay_wechat_service_percentage.to_f != params[:omipay_wechat_service_percentage].to_f
          log_messages << "将Omipay支付宝手续费百分比从#{resource.omipay_alipay_service_percentage}改为#{params[:omipay_alipay_service_percentage]}" if params[:omipay_alipay_service_percentage].present? && resource.omipay_alipay_service_percentage.to_f != params[:omipay_alipay_service_percentage].to_f
          log_messages << "将Supay微信手续费百分比从#{resource.supay_wechat_service_percentage}改为#{params[:supay_wechat_service_percentage]}" if params[:supay_wechat_service_percentage].present? && resource.supay_wechat_service_percentage.to_f != params[:supay_wechat_service_percentage].to_f
          log_messages << "将Supay支付宝手续费百分比从#{resource.supay_alipay_service_percentage}改为#{params[:supay_alipay_service_percentage]}" if params[:supay_alipay_service_percentage].present? && resource.supay_alipay_service_percentage.to_f != params[:supay_alipay_service_percentage].to_f
          log_messages << "将汇率上浮百分比从#{resource.exchange_rate_rise_percentage}改为#{params[:exchange_rate_rise_percentage]}" if params[:exchange_rate_rise_percentage].present? && resource.exchange_rate_rise_percentage.to_f != params[:exchange_rate_rise_percentage].to_f
          log_messages << "将VM信用卡手续费百分比从#{resource.vm_credit_card_service_percentage}改为#{params[:vm_credit_card_service_percentage]}" if params[:vm_credit_card_service_percentage].present? && resource.vm_credit_card_service_percentage.to_f != params[:vm_credit_card_service_percentage].to_f
          log_messages << "将AMEX信用卡手续费百分比从#{resource.amex_credit_card_service_percentage}改为#{params[:amex_credit_card_service_percentage]}" if params[:amex_credit_card_service_percentage].present? && resource.amex_credit_card_service_percentage.to_f != params[:amex_credit_card_service_percentage].to_f
          if !params[:enable_commweb_3ds_auth].nil? && params[:enable_commweb_3ds_auth] != resource.enable_commweb_3ds_auth
            if params[:enable_commweb_3ds_auth]
              log_messages << "开启了CBA 3DS"
            else
              log_messages << "关闭了CBA 3DS"
            end
          end
          log_messages << "将银联信用卡手续费百分比从#{resource.unionpay_credit_card_service_percentage}改为#{params[:unionpay_credit_card_service_percentage]}" if params[:unionpay_credit_card_service_percentage].present? && resource.unionpay_credit_card_service_percentage.to_f != params[:unionpay_credit_card_service_percentage].to_f
          log_messages << "将银联ApplePay手续费百分比从#{resource.apple_pay_service_percentage}改为#{params[:apple_pay_service_percentage]}" if params[:apple_pay_service_percentage].present? && resource.apple_pay_service_percentage.to_f != params[:apple_pay_service_percentage].to_f
          log_messages << "将CBA ApplePay手续费百分比从#{resource.cba_apple_pay_service_percentage}改为#{params[:cba_apple_pay_service_percentage]}" if params[:cba_apple_pay_service_percentage].present? && resource.cba_apple_pay_service_percentage.to_f != params[:cba_apple_pay_service_percentage].to_f
          log_messages << "将CBA GooglePay手续费百分比从#{resource.cba_google_pay_service_percentage}改为#{params[:cba_google_pay_service_percentage]}" if params[:cba_google_pay_service_percentage].present? && resource.cba_google_pay_service_percentage.to_f != params[:cba_google_pay_service_percentage].to_f

          new_no_transaction_fee_over_amount_in_cent = (params[:no_transaction_fee_over_amount_in_yuan].to_f * 100).round

          log_messages << "将满金额免手续费从#{resource.no_transaction_fee_over_amount_in_yuan.presence || "空"}改为#{params[:no_transaction_fee_over_amount_in_yuan].presence || "空"}" if new_no_transaction_fee_over_amount_in_cent != resource.no_transaction_fee_over_amount_in_cent.to_i

          authorize_and_update_resource({ log_message: log_messages.join(", ") })
        end
      end
    end
  end
end
