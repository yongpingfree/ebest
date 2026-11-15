# frozen_string_literal: true

module BeansApp
  class API::V2::Orders < ::API
    namespace :orders, desc: "订单API" do
      route_param :id do
        desc "Omipay 澳洲小程序支付凭证", {
          detail: <<-NOTES.strip_heredoc
            ```json
            {
              "return_code": "SUCCESS",
              "order_no" : "AL1711206265142031",
              "order_string" : "000030-20171120182411-0000",
              "timeStamp" : "15318550943",
              "nonceStr" : "be2f13be2f13be2f13be2f13"
              "package" : "000030-20171120182411-0000",
              "signType" : "MD5",
              "paySign" : "13C8DD13C8DD13C8DD13C8DD"
            }
            ```
          NOTES
        }
        post :omipay_aus_mp_payment do
          check_result = resource.check_omipay_order_paid_by_order_no("mini_program")
          response_error(check_result[:error_msg]) if check_result[:error_msg].present?
          response = resource.make_omipay_aus_mp_order
          if response["return_code"] == "SUCCESS"
            resource.update(omipay_transaction_id: response["order_no"], omipay_platform: MagicBean::OmipayPayment::WECHAT_PLATFORM)
            response
          else
            response_error(response["error_msg"])
          end
        end
      end
    end
  end
end
