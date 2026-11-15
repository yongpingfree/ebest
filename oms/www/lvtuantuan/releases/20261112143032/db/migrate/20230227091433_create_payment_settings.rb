class CreatePaymentSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :payment_settings do |t|
      t.belongs_to :store
      t.float :wechat_service_percentage
      t.float :vm_credit_card_service_percentage
      t.float :unionpay_credit_card_service_percentage
      t.float :exchange_rate_rise_percentage
      t.float :omipay_wechat_service_percentage
      t.float :omipay_alipay_service_percentage
      t.float :supay_wechat_service_percentage
      t.float :supay_alipay_service_percentage
      t.boolean :enable_commweb_3ds_auth, default: true
      t.float :apple_pay_service_percentage
      t.float :cba_apple_pay_service_percentage
      t.float :cba_google_pay_service_percentage
      t.timestamps
    end

    say_with_time "Init Store Payment Settings" do
      MagicBean::PaymentSetting.reset_column_information

      default_config = MagicBean::SiteConfig.default_config
      MagicBean::Store.all.each do |store|
        MagicBean::PaymentSetting.find_or_create_by!(
          store_id: store.id,
          wechat_service_percentage: default_config.wechat_service_percentage,
          vm_credit_card_service_percentage: default_config.vm_credit_card_service_percentage,
          unionpay_credit_card_service_percentage: default_config.unionpay_credit_card_service_percentage,
          exchange_rate_rise_percentage: default_config.exchange_rate_rise_percentage,
          omipay_wechat_service_percentage: default_config.omipay_wechat_service_percentage,
          omipay_alipay_service_percentage: default_config.omipay_alipay_service_percentage,
          supay_wechat_service_percentage: default_config.supay_wechat_service_percentage,
          supay_alipay_service_percentage: default_config.supay_alipay_service_percentage,
          enable_commweb_3ds_auth: default_config.enable_commweb_3ds_auth,
          apple_pay_service_percentage: default_config.apple_pay_service_percentage,
          cba_apple_pay_service_percentage: default_config.cba_apple_pay_service_percentage,
          cba_google_pay_service_percentage: default_config.cba_google_pay_service_percentage,
        )
      end
    end
  end
end
