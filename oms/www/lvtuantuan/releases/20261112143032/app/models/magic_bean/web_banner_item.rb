# frozen_string_literal: true

module MagicBean
  class WebBannerItem < ApplicationRecord
    # scope

    # constants
    AR_PATH_TYPES = %w[
      MagicBean::Item MagicBean::WebCustomList MagicBean::WebCategory
      MagicBean::CouponTemplate MagicBean::CouponPackage MagicBean::Page
      MagicBean::ParentWebCategory
    ]

    NOT_RECORD_TYPES = %w[registration orders refer_friends]

    # attr related macros

    # association macros
    belongs_to :web_banner

    # validation macros
    validates :position, presence: true, numericality: { greater_than: 0, only_integer: true }
    validates :desktop_image_url, presence: true
    validates :mobile_image_url, presence: true
    validates :nav_path_type, inclusion: { in: AR_PATH_TYPES + NOT_RECORD_TYPES } , allow_blank: true
    validate :path_target_exists

    # callbacks
    before_save :set_nav_path

    # other macros

    # class methods

    # instance methods
    def path_target
      @path_target ||= if AR_PATH_TYPES.include?(nav_path_type)
                         if nav_path_type == "MagicBean::WebCategory"
                           MagicBean::WebCategory.children.find_by(id: nav_path_id)
                          elsif nav_path_type == "MagicBean::ParentWebCategory"
                            MagicBean::WebCategory.top.find_by(id: nav_path_id)
                         elsif nav_path_type == "MagicBean::CouponTemplate"
                           nav_path_type.constantize.where(store_id: [web_banner.store_id, nil]).find_by(id: nav_path_id)
                         elsif nav_path_type == "MagicBean::Page"
                           nav_path_type.constantize.find_by(id: nav_path_id)
                         else
                           nav_path_type.constantize.where(store_id: web_banner.store_id).find_by(id: nav_path_id)
                         end
                       elsif NOT_RECORD_TYPES.include?(nav_path_type)
                         send("#{nav_path_type}_path_target")
                       else
                         nil
                       end
    end

    private

    def orders_path_target
      OpenStruct.new({
        title: "我的订单",
        app_path: { type: "orders", params: {} }.to_json
      })
    end

    def registration_path_target
      OpenStruct.new({
        title: "用户注册",
        app_path: { type: "registration", params: {} }.to_json
      })
    end

    def refer_friends_path_target
      OpenStruct.new({
        title: "Referral Program",
        app_path: { type: "referFriends", params: {} }.to_json
      })
    end

    def set_nav_path
      if path_target.present?
        self.nav_path = if nav_path_type == "MagicBean::Page"
                          # 独立页面的网页端请求路径和 app 请求路径不一样
                          JSON.parse(path_target.web_path)
                        else
                          JSON.parse(path_target.app_path)
                        end
        title = if path_target.respond_to?(:title)
                  path_target.title
                elsif path_target.respond_to?(:name)
                  path_target.name
                else
                  ""
                end
        self.nav_path[:title] = title
      else
        # 没有匹配到跳转数据就全置空
        clear_nav_path_attrs
      end
    end

    def clear_nav_path_attrs
      self.nav_path_type = nil
      self.nav_path_id = nil
      self.nav_path = nil
    end

    def path_target_exists
      return unless AR_PATH_TYPES.include?(nav_path_type)

      if path_target.nil?
        self.errors.add(:nav_path_id, "与跳转页面类型数据不匹配")
      end
    end
  end
end
