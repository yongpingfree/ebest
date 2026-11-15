# frozen_string_literal: true
module MagicBean
  class IntegralRecord < ApplicationRecord
    include IntegralRecordWechatTemplateDataConcern, Order::Messages
    VALIDATION_SCOPE = ["activerecord", "attributes", "magic_bean/integral_record", "errors"].freeze

    # scope
    scope :show, -> { where(status: ["pending", "processed"]) }

    # constants
    SEND_MESSAGE_KINDS = [:sign_up, :order_finished]

    enum kind: {
      sign_up: 1,
      order_paid: 2,      # 订单支付奖励，先冻结
      order_finished: 3,  # 订单完成奖励，冻结积分生效
      refund_withdraw: 4, # 收回订单奖励积分（冻结积分）
      suggest: 5,         # 用户反馈奖励
      inviting: 6,        # 邀新
      spent: 7,           # 积分抵扣
      spent_return: 8,    # 积分退回
      admin_assign: 9,    # 管理员发放
      sign_in_each_time: 10, # 单次签到
      sign_in_extra: 11, # 额外签到
      integral_expired: 12, # 积分过期
      recycle: 13, # 回收积分
    }

    # order_paid类型有三种状态，其他类型只有processed状态
    enum status: {
      pending: 1,
      processed: 2,
      hidden: 3
    }

    # 来源
    enum channel: {
      mini_program: 1,
      app: 2,
      web: 3
    }

    # attr related macros

    # association macros
    belongs_to :member
    belongs_to :targetable, polymorphic: true, optional: true

    # validation macros
    # 积分记录是在创建后才去更新有效积分和冻结积分，所以先allow_blank
    validates :available_integral, numericality: { greater_than_or_equal_to: 0, message: I18n.t("not_enough", scope: VALIDATION_SCOPE, locale: I18n.locale) }, allow_blank: true
    validates :blocked_integral, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true

    # callbacks
    after_create :increase_member_available_integral, if: -> { sign_up? || order_finished? || suggest? || inviting? || spent_return? || admin_assign? || sign_in_each_time? || sign_in_extra? }
    after_create :decrease_member_available_integral, if: -> { spent? }
    after_create :decrease_member_blocked_integral, if: -> { order_finished? || refund_withdraw? }
    after_create :increase_member_blocked_integral, if: -> { order_paid? }
    after_create :processed_order_paid_integral_record, if: -> { refund_withdraw? }
    after_create :hidden_order_paid_integral_record, if: -> { order_finished? }
    after_create :create_order_finished_integral_app_text_message, if: -> { order_finished? && app? }
    after_commit :set_integral_quantity, on: :create
    after_commit :send_integral_increased_wechat_template_message, on: :create, if: -> { app? }

    # other macrost
    delegate :nickname, to: :member, prefix: true

    ransacker :kind, formatter: proc { |v| kinds[v] }
    ransacker :channel, formatter: proc { |v| channels[v] }

    def self.rules(amount = 0)
      {
        sign_up: {
          kind: "sign_up",
          integral: MagicBean::SiteConfig.default_config&.sign_up_integral
        },
        suggest: {
          kind: "suggest",
          integral: MagicBean::SiteConfig.default_config&.suggest_integral
        },
        order_paid: {
          kind: "order_paid",
          status: "pending",
          integral: amount
        },
        order_finished: {
          kind: "order_finished",
          integral: amount
        },
        spent: {
          kind: "spent",
          integral: -amount
        },
        spent_return: {
          kind: "spent_return",
          integral: amount
        },
        refund_withdraw: {
          kind: "refund_withdraw",
          integral: -amount
        },
        inviting: {
          kind: "inviting",
          integral: MagicBean::SiteConfig.default_config&.inviting_integral
        },
        admin_assign: {
          kind: "admin_assign",
          integral: amount
        },
        sign_in_each_time: {
          kind: "sign_in_each_time",
          integral: amount
        },
        sign_in_extra: {
          kind: "sign_in_extra",
          integral: amount
        },
        integral_expired: {
          kind: "integral_expired",
          integral: -amount
        },
        recycle: {
          kind: "recycle",
          integral: -amount
        }
      }
    end

    def description
      case kind
      when "sign_up"
        "注册会员获得金币"
      when "order_paid"
        "支付订单 [#{targetable.no}] 获得金币(待入账)"
      when "order_finished"
        "完成订单 [#{targetable.no}] 获得金币"
      when "refund_withdraw"
        no = targetable.is_a?(MagicBean::Order) ? targetable.no : targetable.order_no
        "订单#{no}退货退款 回收金币"
      when "suggest"
        "点评/建议 获得金币"
      when "inviting"
        "邀请好友注册会员获得金币"
      when "spent"
        "订单 [#{targetable.no}] 支付金币"
      when "spent_return"
        no = targetable.is_a?(MagicBean::Order) ? targetable.no : targetable.order_no
        "订单 [#{no}] 关闭/退货退还抵扣金币"
      when "admin_assign"
        "系统发放金币"
      when "sign_in_each_time"
        "单次签到获得金币"
      when "sign_in_extra"
        "签到额外获得金币"
      when "integral_expired"
        "过期金币"
      when "recycle"
        "系统回收金币"
      end
    end

    private

    def channel_prefix
      prefix = app? ? "app_" : nil
    end

    def increase_member_available_integral
      member.with_lock do
        member.increment!("#{channel_prefix}available_integral", integral.to_i.abs)
        member.increment!("#{channel_prefix}cumulative_integral", integral.to_i.abs) unless spent_return?
      end
    end

    # 由于存在会员相同邮箱的数据，导致会员减积分失败，所以在该model内，涉及到积分变动的地方，用decrement!
    def decrease_member_available_integral
      member.with_lock do
        member.decrement!("#{channel_prefix}available_integral", integral.to_i.abs)
      end
    end

    def increase_member_blocked_integral
      member.with_lock do
        member.increment!("#{channel_prefix}blocked_integral", integral.to_i.abs)
      end
    end

    def decrease_member_blocked_integral
      member.with_lock do
        member.decrement!("#{channel_prefix}blocked_integral", integral.to_i.abs)
        member.update_columns(:"#{channel_prefix}blocked_integral" => 0) unless member.send("#{channel_prefix}blocked_integral").positive?
      end
    end

    def set_integral_quantity
      # 这里必须用update!, 确保用户积分为负数时报错
      self.update!(
        available_integral: member.send("#{channel_prefix}available_integral"),
        blocked_integral: member.send("#{channel_prefix}blocked_integral")
      )
    end

    def send_integral_increased_wechat_template_message
      if SEND_MESSAGE_KINDS.include?(kind.to_sym)
        SendSubscribeMessagesJob.perform_later(template_message_params(member.user, "integral_increased"))
      end
    end

    def processed_order_paid_integral_record
      targetable.order_paid_integral_records.first&.processed!
    end

    def hidden_order_paid_integral_record
      targetable.order_paid_integral_records.first&.hidden!
    end
  end
end
