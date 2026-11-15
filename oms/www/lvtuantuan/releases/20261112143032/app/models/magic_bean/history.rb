# frozen_string_literal: true
module MagicBean
  class History < ApplicationRecord
    # constants

    # concerns

    # attr related macros
    enum action_type: {
      viewed: 0,
      searched: 1,
      liked: 2
    }

    enum page_type: {
      item: 1,
      custom_page: 2,
      category: 3,
      coupon_template: 4,
      coupon_package: 5
    }

    # 来源
    enum channel: {
      mini_program: 1,
      app: 2,
      web: 3
    }

    PAGE_TYPE_MAPPING = {
      item: "商品",
      custom_page: "自定义页面",
      category: "分类",
      coupon_template: "优惠券",
      coupon_package: "优惠券礼包"
    }

    # association macros
    belongs_to :operator, polymorphic: true
    belongs_to :operatable, polymorphic: true, optional: true
    belongs_to :store

    # validation macros

    # callbacks
    before_create :set_operatable, unless: :searched?
    after_create :set_items_viewed_count
    after_destroy :set_items_viewed_count

    # other macros

    # scopes
    scope :except_home, -> { where.not(operatable_type: "MagicBean::CustomPage", operatable_id: 1) }
    scope :distinct_user_viewed, -> (time_range) { select(:operator_id).where(created_at: time_range).distinct }

    # class methods

    # instance methods

    class << self
      def title_of(operatable)
        return unless operatable
        operatable_title =
          if operatable.respond_to?(:title)
            operatable.title
          elsif operatable.respond_to?(:name)
            operatable.name
          else
            "#{operatable.class.name.demodulize} - #{operatable.id}"
          end
        "#{PAGE_TYPE_MAPPING[operatable.class.name.demodulize.underscore.to_sym]}\n#{operatable_title}".truncate(25)
      end

      def page_visited_source(store_id)
        MagicBean::History.viewed.except_home.where(created_at: (Time.current.midnight - 30.days)..Time.current.midnight).ransack({ store_id_eq: store_id }).result
          .group(:operatable_id, :operatable_type).size.reject { |k, v| k.compact.blank? }.max(20) { |a, b| a[1] <=> b[1] }.map do |page|
          operatable = page[0][1].classify.constantize.find_by(id: page[0][0])
          [MagicBean::History.title_of(operatable), page[1]]
        end
      end
    end

    private

    def set_operatable
      self.operatable =
        case page_type
        when "custom_page"
          MagicBean::CustomPage.find_by(en_name: params["en_name"])
        when "coupon_template", "coupon_package"
          "magic_bean/#{page_type}".classify.constantize.find_by(code: params["code"])
        when "item", "category"
          "magic_bean/#{page_type}".classify.constantize.find_by(id: params["id"])
        end
      # 接口传过来的store_id不一定是商品的store_id, 所以这里需要reset一下
      self.store_id = operatable.store_id if page_type == "item"
    end

    def set_items_viewed_count
      return unless viewed? && item?

      operator.update_columns(items_viewed_count: operator.viewed_items.count)
    end
  end
end
