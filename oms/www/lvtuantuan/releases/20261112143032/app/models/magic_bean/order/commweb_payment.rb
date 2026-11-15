# frozen_string_literal: true

class MagicBean::Order
  # CommWeb payment 相关
  module CommwebPayment
    extend ActiveSupport::Concern
    @@commweb_logger = ::Logger.new("./log/commweb.log")
    @@cba_apple_pay_logger = ::Logger.new("./log/cba_apple_pay.log")
    @@cba_google_pay_logger = ::Logger.new("./log/cba_google_pay.log")

    def commweb_payment_transaction(options, ebest_channel, cba_transaction_id, entity = "CommwebPayment")
      api_class = "Commweb::#{target_api_name(entity)}".constantize
      logger = custom_logger(entity)

      resp = api_class.transaction(options, ebest_channel)
      logger.info("order id: #{id}, transaction response: #{resp}")

      is_risk, resp_result = check_transaction_data(resp, cba_transaction_id, entity, ebest_channel)

      if is_risk
        resp_result
      else
        if resp["result"] == "SUCCESS"
          commweb_success_handle(resp, ebest_channel, entity)
        elsif resp["result"] == "FAILURE"
          logger.error("pay for order failure: #{id}, #{resp[:failure_message]}")
          [false, I18n.t("commweb.gatewayCode.#{resp["response"]["gatewayCode"]}", default: "交易失败")]
        else
          # 这里有可能是响应超时，需要重新查询下支付状态
          # retrieve_order和retrieve_transaction返回结构不同，retrieve_order要判断status，retrieve_transaction判断result
          retrieve_resp = api_class.retrieve_transaction(no, cba_transaction_id, ebest_channel)
          logger.info("order id: #{id} retrieve resp: #{retrieve_resp}")

          retrieve_is_risk, retrieve_resp_result = check_transaction_data(retrieve_resp, cba_transaction_id, entity, ebest_channel)

          if retrieve_is_risk
            retrieve_resp_result
          else
            if retrieve_resp["result"] == "SUCCESS"
              commweb_success_handle(retrieve_resp, ebest_channel, entity)
            elsif retrieve_resp["result"] == "FAILURE"
              self.update_columns(payment_in_progress: false)
              [false, retrieve_resp.dig("error", "explanation"), default: "交易失败"]
            else
              self.update_columns(payment_in_progress: true)
              CheckCommwebOrderJob.set(wait: 10.second).perform_later(id, cba_transaction_id, entity, ebest_channel)
              [false, "支付正在处理中", default: "交易处理中"]
            end
          end
        end
      end
    end

    def check_transaction_data(resp, cba_transaction_id, entity, ebest_channel)
      # {"response"=>{"gatewayCode"=>"REVIEW_REQUIRED", "review"=>{"decision"=>"PENDING"}, "rule"=>[{"data"=>"NO_LIABILITY_SHIFT", "name"=>"MERCHANT_3D_SECURE", "recommendation"=>"REVIEW", "type"=>"MERCHANT_RULE"}, {"data"=>"535318", "name"=>"MERCHANT_BIN_RANGE", "recommendation"=>"NO_ACTION", "type"=>"MERCHANT_RULE"}, {"name"=>"SUSPECT_CARD_LIST", "recommendation"=>"NO_ACTION", "type"=>"MERCHANT_RULE"}, {"name"=>"TRUSTED_CARD_LIST", "recommendation"=>"NO_ACTION", "type"=>"MERCHANT_RULE"}, {"data"=>"535318", "name"=>"MSO_BIN_RANGE", "recommendation"=>"NO_ACTION", "type"=>"MSO_RULE"}]}}
      risk_resp = resp["risk"]
      if risk_pay_enabled && risk_resp.present? && risk_resp["response"]["gatewayCode"] == "REVIEW_REQUIRED" && risk_resp["response"]["review"]["decision"].upcase != "ACCEPTED"
        # 等待审核
        if risk_resp["response"]["review"]["decision"].upcase == "PENDING"
          risk! if wait_buyer_pay?

          # 风险支付超时通知管理员，不退款
          ::OrderMailer.with(order_no: no).order_close_before_cba_risk_callback.deliver_later if trade_closed?

          CheckCommwebOrderJob.set(wait: 10.minutes).perform_later(id, cba_transaction_id, entity, ebest_channel)

          # 第一个参数代表是否需要审核，第二个参数是处理返回结果
          [true, [true]]
        else
          [true, [false, "支付正在处理中", default: "交易处理中"]]
        end
      else
        [false]
      end
    end

    def pay_with_commeb_session(session_id, ebest_channel)
      transaction do
        # 目前commweb 只有 vm 类型的
        self.try_payment_times = (try_payment_times || 0) + 1

        if no_transaction_fee? || !vm_credit_card_service_percentage.positive?
          self.credit_card_payment_in_cent = payment_in_cent
          self.credit_card_service_percentage = 0
        else
          self.credit_card_payment_in_cent = vm_credit_card_payment_in_cent
          self.credit_card_service_percentage = vm_credit_card_service_percentage
        end

        self.save

        cba_transaction_id = Time.current.to_i

        options = {
          apiOperation: "PAY",
          session: {
            id: session_id
          },
          sourceOfFunds: {
            type: "CARD"
          },
          order: {
            reference: "ebest order pay",
            id: self.no,
            amount: credit_card_payment_in_yuan_num,
            currency: "AUD",
            transaction_id: cba_transaction_id
          }
        }

        commweb_payment_transaction(options, ebest_channel, cba_transaction_id)
      end
    end

    def request_commweb_payment(card, email, ebest_channel)
      @@commweb_logger.info("pay for order: #{id}")

      return [false, "卡信息不能为空"] if card.blank?

      card_number, card_exp_year, card_exp_month, card_cvc = card_pretreatment(card)

      return [false, "请输入正确类型的卡号"] if !card_number.valid_credit_card_brand?(:mastercard, :visa)

      transaction do

        if no_transaction_fee?
          self.credit_card_payment_in_cent = payment_in_cent
          self.credit_card_service_percentage = 0
        else
          self.credit_card_payment_in_cent = send "#{card[:type]}_credit_card_payment_in_cent"
          self.credit_card_service_percentage = send "#{card[:type]}_credit_card_service_percentage"
        end

        self.save

        cba_transaction_id = Time.current.to_i

        options = {
          apiOperation: "PAY",
          sourceOfFunds: {
            type: "CARD",
            provided: {
              card: {
                expiry: {
                  month: card_exp_month,
                  year: card_exp_year,
                },
                number: card_number,
                securityCode: card_cvc
              }
            }
          },
          order: {
            reference: "ebest order pay",
            id: self.no,
            amount: credit_card_payment_in_yuan_num,
            currency: "AUD",
            transaction_id: cba_transaction_id
          }
        }

        options[:customer] = { email: email } if email.present?

        commweb_payment_transaction(options, ebest_channel, cba_transaction_id)
      end
    end

    def hosted_checkout_session(ebest_channel = "app")
      resp = nil
      transaction do
        if no_transaction_fee? || !vm_credit_card_service_percentage.positive?
          self.credit_card_payment_in_cent = payment_in_cent
          self.credit_card_service_percentage = 0
        else
          self.credit_card_payment_in_cent = vm_credit_card_payment_in_cent
          self.credit_card_service_percentage = vm_credit_card_service_percentage
        end

        self.save

        options = {
          apiOperation: "CREATE_CHECKOUT_SESSION",
          interaction: {
            operation: "PURCHASE",
            action: {
              "3DSecure": "MANDATORY"
            },
            returnUrl: "#{Rails.application.credentials.dig(Rails.env.to_sym, :domain)}/orders/commweb_notify",
            displayControl: {
              billingAddress: "HIDE",
              orderSummary: "HIDE"
            }
          },
          order: {
            id: no,
            # https://paymentgateway.commbank.com.au/api/documentation/integrationGuidelines/supportedFeatures/pickAdditionalFunctionality/surcharging.html?locale=zh_CN
            # netAmount: 应用附加费前订单应支付的金额, amount: 订单的总金额，含附加费金额
            amount: credit_card_payment_in_yuan_num, # 手续费由我们控制，这里传加了手续费金额
            currency: "AUD"
          }
        }

        resp = Commweb::Payment.checkout_session(options, ebest_channel)
      end

      @@commweb_logger.debug("Order[#{no}] hosted_checkout_session response: #{resp}")

      resp
    end

    def commweb_success_handle(resp, ebest_channel, entity = "CommwebPayment")
      custom_logger(entity).info("pay for order success: #{id}")
      "MagicBean::#{entity}".constantize.find_or_create_charge_from_webhook(self, resp, ebest_channel)
      pay_success(
        resp["transaction"]["id"],
        resp["order"]["creationTime"].in_time_zone("MagicBean::#{entity}::TIME_ZONE".constantize)
      )

      [true]
    end

    def request_cba_apple_pay_payment(decrypt_token, ebest_channel = "app")
      @@cba_apple_pay_logger.info("pay for order: #{id}")

      card_number = decrypt_token["applicationPrimaryAccountNumber"]
      expiry_month = decrypt_token["applicationExpirationDate"][2..3]
      expiry_year = decrypt_token["applicationExpirationDate"][0..1]
      payment_data = decrypt_token["paymentData"]

      transaction do

        if no_transaction_fee?
          self.credit_card_payment_in_cent = payment_in_cent
          self.credit_card_service_percentage = 0
        else
          self.credit_card_payment_in_cent = cba_apple_pay_payment_in_cent
          self.credit_card_service_percentage = cba_apple_pay_service_percentage
        end

        self.save

        cba_transaction_id = Time.current.to_i

        options = {
          apiOperation: "PAY",
          sourceOfFunds: {
            provided: {
              card: {
                expiry: {
                  month: expiry_month,
                  year: expiry_year
                },
                number: card_number,
                devicePayment:{
                  cryptogramFormat: "3DSECURE",
                  "3DSecure": {
                    onlinePaymentCryptogram: payment_data["onlinePaymentCryptogram"],
                    eciIndicator: payment_data["eciIndicator"]
                  }
                }
              }

            },
            "type": "CARD"
          },
          device: {
            mobilePhoneModel: decrypt_token["deviceManufacturerIdentifier"]
          },
          transaction: {
            source: "INTERNET"
          },
          order: {
            reference: "ebest order apple pay",
            id: self.no,
            amount: credit_card_payment_in_yuan_num,
            currency: "AUD",
            transaction_id: cba_transaction_id,
            walletProvider: "APPLE_PAY"
          },
        }

        commweb_payment_transaction(options, ebest_channel, cba_transaction_id, "CBAApplePayPayment")
      end
    end

    def request_cba_google_pay_payment(payment_token, ebest_channel = "app")
      @@cba_google_pay_logger.info("pay for order: #{id}")

      transaction do

        if no_transaction_fee?
          self.credit_card_payment_in_cent = payment_in_cent
          self.credit_card_service_percentage = 0
        else
          self.credit_card_payment_in_cent = cba_google_pay_payment_in_cent
          self.credit_card_service_percentage = cba_google_pay_service_percentage
        end

        self.save

        cba_transaction_id = Time.current.to_i

        options = {
          order: {
            reference: "ebest order google pay",
            id: self.no,
            amount: credit_card_payment_in_yuan_num,
            currency: "AUD",
            transaction_id: cba_transaction_id,
            walletProvider: "GOOGLE_PAY"
          },
          sourceOfFunds: {
            type: "CARD",
            provided: {
              card: {
                devicePayment: {
                  paymentToken: payment_token
                }
              }
            }
          },
          apiOperation: "PAY"
        }

        # google pay和apple pay用的同个接口，只是参数不同
        commweb_payment_transaction(options, ebest_channel, cba_transaction_id, "CBAGooglePayPayment")
      end
    end

    def target_api_name(entity)
      case entity
      when "CommwebPayment"
        "Payment"
      when "CBAApplePayPayment", "CBAGooglePayPayment"
        "ApplePay"
      end
    end

    def custom_logger(entity)
      case entity
      when "CommwebPayment"
        @@commweb_logger
      when "CBAApplePayPayment"
        @@cba_apple_pay_logger
      when "CBAGooglePayPayment"
        @@cba_google_pay_logger
      end
    end
  end
end
