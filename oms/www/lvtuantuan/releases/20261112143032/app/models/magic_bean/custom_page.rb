# frozen_string_literal: true
module MagicBean
  class CustomPage < ApplicationRecord
    include PageLinksConcern
    include Redis::Objects
    include QrcodeConcern
    include FileUploadConcern

    # scope
    scope :default, -> { where(default: true) }

    # constants
    QRCODE_WIDTH = 1280
    QRCODE_PATH = "pages/custom-page/custom-page"
    MINI_PROGRAM_HOME_PAGE_NAME = "home"
    APP_HOME_PAGE_NAME = "home_v2"

    # attr related macros
    alias_attribute :title, :name

    # association macros
    has_one :share_setting, as: :target, dependent: :destroy, inverse_of: :target
    belongs_to :store
    belongs_to :creator, class_name: "MagicBean::AdminUser", foreign_key: :creator_id, optional: true

    accepts_nested_attributes_for :share_setting

    # validation macros
    validates_presence_of :en_name, :name
    validates_uniqueness_of :en_name, scope: :store
    validate :check_en_name_valid
    before_validation :parse_components, if: :components_changed?
    after_save :update_redis_content
    before_destroy :clear_redis_content

    # callbacks
    after_commit -> { enqueue_generate_qrcode_job(QRCODE_WIDTH) }, if: Proc.new { saved_change_to_name? || saved_change_to_en_name? }

    # other macros
    value :redis_content

    delegate :name, to: :creator, prefix: true, allow_nil: true

    def mini_program_path
      "#{QRCODE_PATH}?en_name=#{en_name}&title=#{name}"
    end

    def app_path
      { type: "customPage", params: { en_name: en_name, title: name } }.to_json
    end

    def name_with_store
      "#{name} - #{store_name}"
    end

    def store_name
      store&.name
    end

    def collaborators
      @collaborators ||= MagicBean::AdminUser.where(id: collaborator_ids)
    end

    def can_be_editted_by?(user_id)
      (user_id == creator_id) || user_id.in?(collaborator_ids)
    end

    def app_share_url
      @app_share_url ||= "#{url_origin}/app_shares?type=customPage&en_name=#{en_name}"
    end

    def url_origin
      @url_origin ||= Rails.application.credentials.dig(Rails.env.to_sym, :domain)
    end

    def app_home_page?
      en_name == APP_HOME_PAGE_NAME
    end

    private

    def check_en_name_valid
      if en_name && en_name =~ %r([\s+/?%#&=.\p{Han}])
        errors.add(:en_name, "英文名不可包括中文、空格或 ‘+ / ? % # & = .’ 中的任意字符")
      end

      if en_name && en_name.length > 24
        errors.add(:en_name, "英文名长度不能超过24")
      end
    end

    def parse_components
      self.components = JSON.parse(components) unless components.is_a?(Array)
    end

    def update_redis_content
      self.redis_content = BeansApp::API::Entities::CustomPage.represent(self).to_json
    end

    def clear_redis_content
      self.redis_content.clear
    end

    # 生成二维码需要的参数
    def qrcode_params
      {
        sence: "en_name=#{en_name}",
        path: QRCODE_PATH
      }
    end
  end
end
