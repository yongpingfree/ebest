# frozen_string_literal: true
module MagicBean
  class User < ApplicationRecord
    include PeriodScopeConcern
    include UserTrackableConcern
    include Redis::Objects

    # scope
    scope :host, -> { where(is_host: true) }
    scope :registered, -> { where(deleted_by_user_at: nil) }

    # constants
    enum gender: { unknow: 0, male: 1, female: 2, prefer_not_to_say: 3 }
    enum origin_gender: { unknow: 0, male: 1, female: 2, prefer_not_to_say: 3 }, _prefix: true
    enum sign_up_channel: {
      mini_program: 1,
      app: 2,
      web: 3
    }
    RECENT_ITEM_WORDS_LENGTH = 20
    PASSWORD_PATTERN = /(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])(?=.*[-=?+._!@#$%^&*])/
    GUESS_YOU_LIKE_HASH_KEY = "store-store_id-channel"
    MAX_FINGERPRINT_COUNT = 10
    PLACE_ORDER_LIMIT_KEY = "place_order_limit_at_the_same_time"

    # attr related macros
    delegate :id, :mobile, to: :member, prefix: true, allow_nil: true

    has_secure_password(validations: false)

    # association macros
    belongs_to :selected_store, optional: true, class_name: "MagicBean::Store"
    # 注意：新增association需要在rebase_other_user方法里面处理
    has_many :orders, -> { order(created_at: :desc) }
    has_many :order_items, through: :orders
    has_many :addresses, -> { order(is_default: :desc, created_at: :desc) }, dependent: :destroy
    has_many :invoices, dependent: :destroy
    has_one :shopping_cart, dependent: :destroy
    has_many :shopping_cart_items, through: :shopping_cart
    # 当日达购物车
    has_one :same_day_delivery_cart, dependent: :destroy
    has_many :same_day_delivery_cart_items, through: :same_day_delivery_cart
    has_many :after_sales, -> { order(created_at: :desc) }
    has_many :histories, as: :operator
    has_many :coupons
    has_many :coupon_templates, through: :coupons
    has_many :coupon_packages_users
    has_and_belongs_to_many :coupon_packages
    has_many :normal_orders
    has_many :virtual_orders
    has_many :auction_orders
    has_many :same_day_delivery_orders
    has_many :groupon_orders, -> { trade_not_close }
    has_many :groupons, through: :groupon_orders, source: :groupon
    has_many :joined_groupons, -> (id) { where.not(creator_id: id) }, through: :groupon_orders, source: :groupon
    has_many :created_groupons, foreign_key: "creator_id", class_name: "MagicBean::Groupon"
    has_many :user_suggestions, dependent: :destroy
    has_many :user_recommended_products, dependent: :destroy
    has_many :comments
    has_one :member, inverse_of: :user
    has_many :subscribe_records
    has_many :event_form_records
    has_many :overseas_student_applications, dependent: :destroy
    has_many :form_item_applications, dependent: :destroy
    accepts_nested_attributes_for :member

    # 以下不需要rebase处理
    has_many :push_message_read_logs, dependent: :destroy
    has_many :users_push_messages, dependent: :destroy
    has_many :app_text_messages, dependent: :destroy
    has_one :message_unread_counter, dependent: :destroy
    has_many :item_search_histories, dependent: :destroy
    has_many :sku_in_stock_notices, dependent: :destroy
    has_many :live_room_subscriptions, dependent: :destroy
    has_many :live_room_lottery_winning_users, dependent: :destroy
    has_many :sign_in_reward_histories, dependent: :destroy
    has_many :sign_in_histories, dependent: :destroy
    has_many :auction_bids, class_name: "MagicBean::Auction::Bid", dependent: :destroy
    has_many :auction_automatic_bids, class_name: "MagicBean::Auction::AutomaticBid", dependent: :destroy
    has_many :auction_activity_participations, class_name: "MagicBean::Auction::ActivityParticipation", dependent: :destroy
    has_many :user_histories, dependent: :destroy

    action_store :like, :item, class_name: "MagicBean::Item", counter_cache: true
    action_store :like, :comment, class_name: "MagicBean::Comment", counter_cache: true

    # validation macros
    validates_format_of :mobile, with: /\A^1[3|4|5|6|7|8|9][0-9]{9}$\z/, if: :mobile?
    validates :locale, presence: true, inclusion: { in: I18n.available_locales.map(&:to_s) }
    validates_length_of :password, within: 1..72, allow_blank: true
    # validates :password, format: { with: PASSWORD_PATTERN, message: I18n.t("error.user.password_should_contain", locale: I18n.locale) }, if: :password_digest_changed?
    validates_confirmation_of :password, allow_blank: true

    # callbacks
    before_validation :reset_selected_store_id
    after_commit :create_shopping_cart, :create_same_day_delivery_cart, :init_message_unread_counter, :send_new_user_message, on: :create
    after_commit :check_info_finished, if: -> { saved_change_to_gender? || saved_change_to_origin_gender? || saved_change_to_password_digest? }

    # other macros
    hash_key :store_shopping_cart_items_hash, expireat: lambda { Time.current + 1.hour }
    hash_key :simple_store_shopping_cart_items_hash, expireat: lambda { Time.current + 1.hour }
    hash_key :shopping_cart_items_delivery_time, expireat: lambda { Time.current + 1.hour }

    ransacker :sign_up_channel, formatter: proc { |v| sign_up_channels[v] }

    def self.fingerprint_signatures_contains_any(fingerprint_signature)
      find_by(Arel.sql("fingerprint_signatures && ARRAY['#{fingerprint_signature}']::varchar[]"))
    end

    # 只拿最近一个月的消息
    def calculate_push_messages_count(store_id)
      push_start_time = [created_at, 1.month.ago.beginning_of_day].max
      
      # 有门店的推送会记录到users_push_messages表（逻辑在enqueue_push_app_notification_job）
      store_push_message_ids = UsersPushMessage.where(user_id: id).map(&:push_message_id)
      chain = PushMessage.where("user_ids @> ARRAY[?]::integer[]", [id]).or(PushMessage.where(user_ids: [])).pushed.where(push_at: push_start_time..Time.current)
      basic_relation = chain.where(store_id: store_id, id: store_push_message_ids).or(chain.where(store_id: nil))
                          .joins("LEFT JOIN push_message_read_logs ON push_message_read_logs.push_message_id = push_messages.id AND push_message_read_logs.user_id = #{id}")
                          .where("push_messages.push_at >= ? AND push_message_read_logs.user_id IS NULL", created_at)

      MagicBean::PushMessage.kinds.keys.inject({}) do |hash, kind|
        hash.merge(kind => basic_relation.where(kind: kind).count)
      end
    end

    def like_items_count
      like_items.count
    end

    def wait_buyer_pay_orders_count
      orders.wait_buyer_pay.count
    end

    def wait_seller_send_goods_count
      orders.wait_seller_send_goods.count
    end

    def wait_buyer_confirm_goods_count
      orders.wait_buyer_confirm_goods.count
    end

    def after_sales_count
      after_sales.where.not(status: ["finished", "closed", "seller_refuse_buyer"]).count
    end

    def pick_address(address_id = nil)
      if address_id.blank?
        addresses.first
      else
        addresses.find_by(id: address_id) || addresses.first
      end
    end

    def viewed_items
      MagicBean::Item.joins("join (#{MagicBean::History.item.viewed.where(operator: self).group(:operatable_id).select('operatable_id, max(created_at) max_created_at').to_sql}) histories ON items.id = histories.operatable_id").order("histories.max_created_at desc")
    end

    def usable_coupons_for(order, channel)
      @usable_coupons ||= coupons.usable.includes(:coupon_template, :store).where(store_id: [nil, order.store_id]).select { |coupon| coupon.usable?(order, channel) }
    end

    def rebase_other_user(user)
      ActiveRecord::Base.transaction do
        user_info = user.as_json(except: [:id, :created_at, :updated_at, :unionid, :new_user, :password_digest, :fingerprint_signatures])
                      .merge!({ "valid_orders_count" => user.valid_orders_count + valid_orders_count,
                                "items_viewed_count" => user.items_viewed_count + items_viewed_count,
                                "open_id" => user.open_id || open_id,
                                "deleted_mini_open_id" => open_id })
        # 两个user都是新用户，合并后的user才是新用户
        user_info["new_user"] = [new_user, user.new_user].all? true
        user_info["is_overseas_student"] = [is_overseas_student, user.is_overseas_student].any?
        # 合并新旧用户指纹
        user_info["fingerprint_signatures"] = (user.fingerprint_signatures + fingerprint_signatures).uniq
        user.overseas_student_applications.update_all(user_id: id)
        user.orders.update_all(user_id: id)
        user.addresses.update_all(user_id: id)
        if shopping_cart.present?
          duplicated_skus = user.shopping_cart_items.with_deleted.where(stock_keeping_unit_id: shopping_cart_items.with_deleted.select(:stock_keeping_unit_id))
          duplicated_skus.map(&:really_destroy!)
          user.shopping_cart_items.update_all(shopping_cart_id: shopping_cart.id)
        else
          user.shopping_cart.update_columns(user_id: id)
        end

        if user.same_day_delivery_cart
          if same_day_delivery_cart.present?
            duplicated_skus = user.same_day_delivery_cart_items.with_deleted.where(stock_keeping_unit_id: same_day_delivery_cart_items.with_deleted.select(:stock_keeping_unit_id))
            duplicated_skus.map(&:really_destroy!)
            user.same_day_delivery_cart_items.update_all(same_day_delivery_cart_id: same_day_delivery_cart.id)
          else
            user.same_day_delivery_cart.update_columns(user_id: id)
          end
        end

        user.after_sales.update_all(user_id: id)
        user.histories.update_all(operator_id: id)
        user.coupons.update_all(user_id: id)
        # 先删除相同的优惠券礼包
        user.coupon_packages_users.where(coupon_package_id: coupon_packages_users.select(:coupon_package_id)).delete_all
        user.coupon_packages_users.update_all(user_id: id)
        user.created_groupons.update_all(creator_id: id)
        user.user_suggestions.update_all(user_id: id)
        user.user_recommended_products.update_all(user_id: id)
        user.comments.update_all(user_id: id)
        user.subscribe_records.update_all(user_id: id)
        user.event_form_records.update_all(user_id: id)

        user.destroy!
        update!(user_info)
      end
    end

    def set_redis_store_shopping_cart_items(postal_code, suburb, store_id, full = true)
      my_shopping_cart_items = (shopping_cart || create_shopping_cart).shopping_cart_items.where(store_id: store_id)
      includes_relations = full ? [stock_keeping_unit: [item: [:on_sale_skus, :cutoff_times, :store, :translations]]] : [stock_keeping_unit: [item: [:on_sale_skus, :translations]]]
      # 按更新时间倒叙排序
      sort_cart_items = my_shopping_cart_items.includes(includes_relations).order(updated_at: :desc).partition { |cart_item| cart_item.stock_keeping_unit.is_on_sale? }.flatten
      current_store = MagicBean::Store.find(store_id)
      store_shopping_cart_items = [
        {
          store: current_store,
          shopping_cart_items: sort_cart_items
        }
      ]

      pending_sku_ids = sku_in_stock_notices.pending.pluck(:stock_keeping_unit_id)

      active_top_left_item_hash = {}
      MagicBean::TopLeftItemTag.active.each do |tag|
        active_top_left_item_hash[tag.icon] = tag.item_ids
      end

      if full
        result = BeansApp::API::Entities::StoreShoppingCartItem.represent(
          store_shopping_cart_items, serializable: true,
          pending_sku_ids: pending_sku_ids,
          is_new_user: new_user,
          active_top_left_item_hash: active_top_left_item_hash
        ).to_json
      else
        result = BeansApp::API::Entities::SimpleStoreShoppingCartItem.represent(
          store_shopping_cart_items, serializable: true,
          pending_sku_ids: pending_sku_ids,
          is_new_user: new_user,
          active_top_left_item_hash: active_top_left_item_hash
        ).to_json
      end

      JSON.parse result
    end

    def get_redis_store_shopping_cart_items(postal_code, suburb, full = true)
      key = cal_store_shopping_cart_items_hash_key postal_code, suburb
      items_json_string = full ? store_shopping_cart_items_hash[key] : simple_store_shopping_cart_items_hash[key]
      items_json_string.blank? ? nil : JSON.parse(items_json_string)
    end

    def reset_redis_store_shopping_cart_items
      store_shopping_cart_items_hash.clear
      simple_store_shopping_cart_items_hash.clear
      shopping_cart_items_delivery_time.clear
    end

    def cal_store_shopping_cart_items_hash_key(postal_code, suburb)
      "#{postal_code}-#{suburb}"
    end

    def set_redis_shopping_cart_items_delivery_time(postal_code, suburb)
      # key = cal_store_shopping_cart_items_hash_key postal_code, suburb
      skus = MagicBean::StockKeepingUnit.includes(item: [:store, :cutoff_times]).where(id: shopping_cart_items.pluck(:stock_keeping_unit_id))
      skus_with_delivery_time = BeansApp::API::Entities::StockKeepingUnitDeliveryTime.represent(skus, serializable: true)
      sku_hash = skus_with_delivery_time.inject({}) do |hash, sku|
                   hash.merge(sku[:id] => sku.except(:id))
                 end
      # self.shopping_cart_items_delivery_time[key] = sku_hash.to_json

      sku_hash
    end

    def get_redis_shopping_cart_items_delivery_time(postal_code, suburb)
      key = cal_store_shopping_cart_items_hash_key postal_code, suburb
      delivery_time_string = shopping_cart_items_delivery_time[key]
      delivery_time_string.blank? ? nil : JSON.parse(delivery_time_string)
    end

    def batch_read_app_text_messages(kind)
      app_text_messages.send(kind).where(read_at: nil).update_all(read_at: Time.current)
      
      if kind == "all"
        message_unread_counter.update_columns(order_tracking_count: 0, customer_service_count: 0, sku_in_stock_count: 0)
      else
        message_unread_counter.update_column("#{kind}_count", 0)
      end
    end

    def fuzzy_name
      @fuzzy_name ||= nickname.blank? ? "用户****" : "#{nickname[0]}****#{nickname[-1]}"
    end

    def deleted_by_user?
      deleted_by_user_at? # TODO: 后面需要加上 6 个月前注销的判断
    end

    def delete_account
      return true if deleted_by_user?

      touch(:deleted_by_user_at)
    end

    def restore_account
      update(deleted_by_user_at: nil)
    end

    def sku_bought_quantity(sku_id)
      MagicBean::OrderItem.where(order: orders.effective).where(stock_keeping_unit_id: sku_id).sum(:quantity)
    end

    def admin_multi_lang_config
      @admin_multi_lang_config ||= MagicBean::MultiLangConfig.config(selected_store_id, locale, :admin)
    end

    def pending_student_application_exists?
      overseas_student_applications.pending.exists?
    end

    def has_password?
      password_digest?
    end

    private

    def create_shopping_cart
      MagicBean::ShoppingCart.find_or_create_by(user_id: id)
    end

    def create_same_day_delivery_cart
      MagicBean::SameDayDeliveryCart.find_or_create_by(user_id: id)
    end

    def init_message_unread_counter
      MagicBean::MessageUnreadCounter.find_or_create_by(user_id: id)
    end

    def reset_selected_store_id
      self.selected_store_id = nil if selected_store_id.to_i.zero?
    end

    def send_new_user_message
      return unless MagicBean::Store.exists?(selected_store_id)

      content = admin_multi_lang_config.new_user_letter_message_text
      custom_page_id = admin_multi_lang_config.new_user_letter_custom_page_id.to_s.strip.to_i

      return unless new_user_message_config_valid?(selected_store_id, content, custom_page_id)

      message = app_text_messages.new(
        title: I18n.t("activerecord.attributes.magic_bean/app_text_message.titles.letter_for_new_user", locale: locale),
        content: content,
        kind: :customer_service,
        target_type: "MagicBean::CustomPage",
        target_id: custom_page_id
      )

      message.save
    end

    def new_user_message_config_valid?(store_id, message_text, letter_page_id)
      message_text.present? && MagicBean::CustomPage.exists?(store_id: store_id, id: letter_page_id)
    end

    # 用戶第一次编辑保存补全了 性別、生日、邮箱、密码 所有信息，一次性奖励，10澳元无门槛优惠券（14天有效）
    def check_info_finished
      return if all_info_finished || !member

      if (origin_gender? || gender?) && password_digest? && member.birthday? && member.email?
        update(all_info_finished: true)
        enqueue_reward_info_finished_job
      end
    end

    # 10澳元无门槛优惠券（14天有效）
    def reward_info_finished
      template = web? ? MagicBean::CouponTemplate.web_info_finished(selected_store_id) : MagicBean::CouponTemplate.info_finished(selected_store_id)
      return unless template

      template.generate_coupon_and_assign_with_notification(id)
    end

    def enqueue_reward_info_finished_job
      RewardInfoFinishedJob.perform_later(id)
    end
  end
end
