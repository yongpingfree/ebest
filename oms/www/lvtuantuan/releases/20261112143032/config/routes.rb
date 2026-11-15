# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root to: "home#index"

  constraints(lambda do |request|
    admin_user_id = request.env["rack.session"][:admin_user_id]
    Rails.env.development? || (admin_user_id.present? && MagicBean::AdminUser.find_by(id: admin_user_id)&.active?)
  end) do
    mount Sidekiq::Web => "/sidekiq"
    mount PgHero::Engine, at: "pghero"

    resources :orders, only: [] do
      get :order_invoice
    end
  end
  post "access_tokens/notify" => "access_tokens#notify" unless Rails.env.production?
  post "qiyukf_push/android", to: "qiyukf_push#android"

  resources :orders, only: [] do
    collection do
      post :notify
      post :union_pay_notify
      post :refund_notify
      post :omipay_notify
      post :omipay_aus_mp_notify
      post :supay_notify
      post :stripe_notify
      get :commweb_notify
      get :commweb_checkout
      get :commweb_failure
      get :apple_pay_notify
    end
  end

  resources :aliexpress, only: [] do
    collection do
      get :token
      get :oversea_token
    end
  end

  resources :shopline, only: [] do
    collection do
      post :paid_order_notify
      post :refund_notify
    end
  end

  post "agora_callbacks" => "agora_callbacks#index"

  resources :home, only: [:index]
  resources :pages, only: [:index, :show] do
    collection do
      get "about_us"
      get "contact"
      get "member_info"
      get "integral_rules"
      get "delete_user"
      get "terms_and_conditions"
      get "privacy_policy"
      get "overseas_student_application"
      get "coupon_description"
      get "cooperation"
    end
  end

  resources :report_pages, only: [:show]

  resources :event_pages, only: :show, param: :slug
  resources :event_form_records, only: [:create, :index, :update]
  resources :app_download_channels, only: [:show]
  get "app_shares" => "app_shares#index"
  get "h5_register" => "app_shares#h5_register"
  get "register_success" => "app_shares#register_success"
  get "newbie_coupon_templates" => "app_shares#newbie_coupon_templates"

  get "h5_register_en" => "app_shares#h5_register_en"
  get "register_success_en" => "app_shares#register_success_en"
  get "newbie_coupon_templates_en" => "app_shares#newbie_coupon_templates_en"

  resources :members do
    collection do
      get "email_confirmation"
    end
  end

  # CommWeb payment
  resources "commweb_payments", only: [] do
    collection do
      get "checkout"
    end
  end

  namespace :app do
    mount BeansApp::API => "/"
    mount GrapeSwaggerRails::Engine => "api/doc" unless Rails.env.production?
  end

  namespace :mgt do
    mount BeansAdmin::API => "/"
    mount GrapeSwaggerRails::Engine => "api/doc" unless Rails.env.production?
  end

  namespace :wms do
    mount Wms::API => "/"
    mount GrapeSwaggerRails::Engine => "api/doc" unless Rails.env.production?
  end

  namespace :fresh do
    mount Fresh::API => "/"
    mount GrapeSwaggerRails::Engine => "api/doc" unless Rails.env.production?
  end
end
