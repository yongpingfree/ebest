# frozen_string_literal: true
module MagicBean
  class Groupon < ApplicationRecord
    include AASM
    include GrouponWechatTemplateDataConcern
    # scope
    scope :not_closed, -> { where(status: ["waiting", "filled"]) }

    # constants
    # 自创建起24小时内没拼团成功就取消拼团
    EXPIRED_HOURS_AFTER_CREATED = 24

    # attr related macros
    enum status: {
      waiting: 1,
      filled: 2,
      finished: 3,
      canceled: 4,
      free: 5           #免拼
    }

    # 订单来源
    enum channel: {
      mini_program: 1,
      app: 2,
      admin: 3,
      web: 4
    }

    aasm column: :status, enum: true do
      state :waiting, initial: true
      state :filled
      state :finished
      state :canceled
      state :free

      event :wait do
        transitions from: :filled, to: :waiting
      end

      event :fill_up do
        transitions from: :waiting, to: :filled
      end

      event :finish, after_commit: [:send_wechat_template_message, :push_groupon_notification] do
        # 可能会存在订单创建时不需要支付的场景，会从waiting状态过度到finished
        transitions from: [:waiting, :filled],
          to: :finished,
          after: [
            :update_finished_at,
            :finish_big_groupon_activity
          ]
      end

      event :auto_finish, after_commit: [:send_wechat_template_message, :push_groupon_notification] do
        transitions from: [:waiting, :filled],
        to: :free,
        after: [
          :update_finished_at
        ]
      end

      event :expire, after_commit: [:send_wechat_template_message, :push_groupon_notification] do
        transitions form: [:waiting, :filled],
          to: :canceled,
          after: [
            :refund_all_paid_orders,
            :close_all_wait_buyer_pay_orders
          ]
      end
    end

    ransacker :status, formatter: proc { |v| statuses[v] }

    # association macros
    belongs_to :creator, class_name: "User", optional: true
    belongs_to :groupon_activity
    belongs_to :sku_groupon, optional: true
    has_many :groupon_orders, -> { trade_not_close }
    has_many :users, through: :groupon_orders

    # validation macros
    before_validation :set_store_id

    # callbacks
    after_commit :enqueue_auto_finish_groupon_job, on: :create

    delegate :nickname, :mobile, to: :user, prefix: true
    delegate :user_count, :price_range, :rules, to: :groupon_activity, prefix: true
    delegate :item_price_range, :item_title, :item_id, :item, to: :groupon_activity

    # other macros

    ransacker :status, formatter: proc { |v| statuses[v] }

    class << self
      def creating_by_new_order(order)
        create({
                 creator_id: order.user_id,
                 groupon_activity_id: order.groupon_activity_id,
                 sku_groupon_id: order.sku_groupon_id,
                 expired_at: calculate_expired_at(order),
                 channel: order.channel
               })
      end

      def calculate_expired_at(order)
        activity = order.groupon_activity
        activity.expired_hours.zero? ? order.groupon_activity.end_at : (order.paid_at + activity.expired_hours.hours)
      end

      def creating_by_big_groupon_activity(activity)
        create({
                 groupon_activity_id: activity.id,
                 expired_at: activity.end_at,
                 channel: :admin
               })
      end
    end

    def required_joined_count
      groupon_activity_user_count - users.count
    end

    def creator_groupon_order
      groupon_orders.find_by(user_id: creator_id)
    end

    def joined_groupon_orders
      groupon_orders.where.not(user_id: creator_id)
    end

    def check_finishing_status
      finish! if groupon_orders.paid.count == groupon_activity_user_count
    end

    def mini_program_path
      "pages/products/groupon-detail/groupon-detail?id=#{id}".freeze
    end

    def app_path

    end

    private

    def enqueue_auto_finish_groupon_job
      AutoFinishGrouponJob.set(wait_until: [expired_at, groupon_activity.end_at].min).perform_later(id)
    end

    def update_finished_at
      update(finished_at: Time.current)
    end

    def send_wechat_template_message
      type = aasm.to_state.in?([:finished, :free]) ? "groupon_finished" : "groupon_canceled"
      groupon_orders.each { |order| order.send_wechat_template_message(type) }
    end

    def push_groupon_notification
      message = aasm.to_state.in?([:finished, :free]) ? "您的拼团已完成，请查看" : "您的拼团未完成，请查看"
      user_ids = groupon_orders.map { |order| order.user_id }
      ::MagicBean::AppNotifier.enqueue_app_push_job("拼团结果", message, user_ids, app_link: { type: "groupon", params: { id: id } }.to_json)
    end

    def refund_all_paid_orders
      groupon_orders.wait_seller_send_goods.each(&:refund!)
    end

    # 多人团，拼团自动过期后应该关闭所有未支付的订单
    # 避免拼团关闭后订单还能支付
    def close_all_wait_buyer_pay_orders
      groupon_orders.wait_buyer_pay.each(&:close!)
    end

    def set_store_id
      self.store_id = groupon_activity.store_id
    end

    def finish_big_groupon_activity
      groupon_activity.update(end_at: Time.current) if groupon_activity.is_a?(MagicBean::BigGrouponActivity)
    end
  end
end
