# frozen_string_literal: true
module MagicBean
  class MarketingMessage < ApplicationRecord
    # concerns
    include AASM
    include AASMExtendConcern

    # constants
    SMS_PLATFORMS = %w[aws].freeze

    # 查询用户模板, order_scope 对应 template_user_ids_condition 中的下单条件
    USER_QUERY_TEMPLATES = {
      no_order_in_30_days_zh: { label: "30天未下单用户_中文", locale: :zh, order_scope: :no_order_in_30_days },
      no_order_in_30_days_en: { label: "30天未下单用户_英文", locale: :en, order_scope: :no_order_in_30_days },
      registered_7_days_no_order_zh: { label: "注册7天，未下单用户_中文", locale: :zh, order_scope: :registered_no_order },
      registered_7_days_no_order_en: { label: "注册7天，未下单用户_英文", locale: :en, order_scope: :registered_no_order },
      no_reorder_14_days_after_first_order_zh: { label: "首单后14天，未下单用户_中文", locale: :zh, order_scope: :no_reorder_after_first_order },
      no_reorder_14_days_after_first_order_en: { label: "首单后14天，未下单用户_英文", locale: :en, order_scope: :no_reorder_after_first_order }
    }.freeze

    LOCALE_VALUES = {
      zh: %w[zh-CN zh-TW],
      en: %w[en]
    }.freeze

    # attr related macros
    enum state: { draft: 0, pending: 1, pushed: 2 }

    # registered_never_ordered_ids 分批查询 orders 的每批 id 数量
    REGISTERED_QUERY_BATCH_SIZE = 20_000

    # association macros
    belongs_to :store
    belongs_to :admin_user

    # validation macros
    validates :content, presence: true
    validates :sms_platform, presence: true, inclusion: { in: SMS_PLATFORMS }
    validates :push_at, presence: true, unless: :draft?
    validates :push_at, timeliness: { on_or_after: lambda { Time.current }, type: :datetime, allow_blank: true, if: -> { draft? || pending? } }
    # 营销短信不再默认发送门店全部用户, 排程发布前必须明确指定用户名单(模板名单或手动添加)
    validate :recipients_presence, if: :pending?

    # callbacks
    after_commit :enqueue_pushed_job , on: [:create, :update]

    # other macros
    aasm :state, column: :state, enum: true, requires_lock: true do
      state :draft, initial: true
      state :pending
      state :pushed

      event :push, after_commit: [:enqueue_send_message_job], guard: :recipients_present? do
        transitions from: [:draft, :pending], to: :pushed
      end
    end

    ransacker :state, formatter: proc { |v| states[v] }

    # class methods
    def self.template_users(template_key, store_id:)
      template = USER_QUERY_TEMPLATES.fetch(template_key.to_sym)

      users = User.registered.joins(:member)
        .where(selected_store_id: store_id)
        .where(accept_marketing_message: true)
        .where.not(members: { mobile: nil })
        .where(locale: LOCALE_VALUES.fetch(template[:locale]))

      users.where(id: template_user_ids_condition(template[:order_scope], users))
    end

    # "已下单"以成功支付(paid_at 非空)为准:
    # - no_order_in_30_days: 有下单记录, 但最后一单在 30 天前
    # - registered_no_order: 注册满 7 天且从未下单
    # - no_reorder_after_first_order: 只有一笔首单, 且首单距今满 14 天
    def self.template_user_ids_condition(order_scope, users_scope)
      placed_orders = Order.where.not(paid_at: nil)

      case order_scope
      when :no_order_in_30_days
        placed_orders.group(:user_id).having("MAX(paid_at) <= ?", 30.days.ago).select(:user_id)
      when :registered_no_order
        registered_never_ordered_ids(users_scope)
      when :no_reorder_after_first_order
        placed_orders.group(:user_id).having("COUNT(*) = 1 AND MIN(paid_at) <= ?", 14.days.ago).select(:user_id)
      else
        raise ArgumentError, "unknown order_scope: #{order_scope}"
      end
    end

    # 注册满 7 天且从未下单: 候选用户(已按门店/locale等过滤)通常较少, 分三步查询
    # 1. 先取候选用户 id; 2. 分批查这些 id 里已下单的; 3. 内存做差集。
    # 避免对大 orders 表做 NOT IN 全量物化, orders 侧走 user_id 索引
    def self.registered_never_ordered_ids(users_scope)
      candidate_ids = users_scope.where("users.created_at <= ?", 7.days.ago).ids
      ordered_ids = candidate_ids.each_slice(REGISTERED_QUERY_BATCH_SIZE).flat_map do |slice|
        Order.where.not(paid_at: nil).where(user_id: slice).distinct.pluck(:user_id)
      end
      candidate_ids - ordered_ids.uniq
    end

    def users
      @users ||= User.includes(:member).where(id: user_ids)
    end

    def manual_users
      @manual_users ||= User.includes(:member).where(id: manual_user_ids)
    end

    # 发送名单 = 模板名单(user_ids) + 手动添加用户(manual_user_ids)
    def recipient_ids
      (user_ids.to_a + manual_user_ids.to_a).map(&:to_i).uniq
    end

    def enqueue_pushed_job
      MarketingMessageJob.set(wait_until: push_at).perform_later(id) if can_enqueue_push_job?
    end

    def can_enqueue_push_job?
      (state_previously_changed? || push_at_previously_changed?) && pending?
    end

    def enqueue_send_message_job
      # 只发送名单内用户, 且仍需满足接收营销短信的条件
      push_mobiles = User.where(id: recipient_ids)
        .where(selected_store_id: store_id, accept_marketing_message: true)
        .joins(:member)
        .where.not(members: { mobile: nil })
        .order("users.id")
        .pluck("users.id", "members.mobile")

      push_mobiles.each do |_user_id, mobile|
        MarketingSmsJob.perform_later(mobile, content, sms_platform)
      end
    end

    private
    def recipients_presence
      return if recipient_ids.present?

      errors.add(:user_ids, :blank)
    end

    def recipients_present?
      recipient_ids.present?
    end
  end
end
