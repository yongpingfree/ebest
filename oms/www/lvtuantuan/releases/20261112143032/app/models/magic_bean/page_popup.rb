# frozen_string_literal: true
module MagicBean
  class PagePopup < ApplicationRecord
    include PageLinksConcern

    # scope
    default_scope { order(position: :asc) }
    scope :active, -> { where(":current_time BETWEEN start_at AND end_at", current_time: Time.current) }
    scope :without_for_new_user, -> { where(for_new_user: false) }

    # constants

    # attr related macros
    enum page_type: {
      home: 1, # 首页
      mine: 2, # 我的页面
    }

    # association macros
    belongs_to :store, optional: true

    # validation macros
    validates_presence_of :title, :start_at, :end_at, :image
    validate :no_fullscreen_for_new_user
    validate :check_start_at_and_end_at_valid
    before_validation :reset_is_fullscreen

    # callbacks

    # other macros

    def active?
      Time.current.between?(start_at, end_at)
    end

    def path_name
      JSON.parse(path)["name"] if path.present?
    rescue JSON::ParserError
      nil
    end

    def au_suburbs
      au_suburb_ids.present? ? MagicBean::AuSuburb.where(id: au_suburb_ids) : []
    end

    private

    def check_start_at_and_end_at_valid
      errors.add(:base, I18n.t("errors.messages.start_at_can_not_later_than_end_at")) if start_at && end_at && start_at > end_at
    end

    def no_fullscreen_for_new_user
      errors.add(:base, "新用户和全屏不能同时配置") if for_new_user && is_fullscreen
    end

    # 我的页面弹窗不可全屏
    def reset_is_fullscreen
      self.is_fullscreen = false if mine?
    end
  end
end
