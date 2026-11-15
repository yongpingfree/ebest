# frozen_string_literal: true

module MagicBean
  class Auction::Activity < ApplicationRecord
    # constants
    AUTO_RENEWAL_END_AT_INTERVAL = 30.minutes
    PAYMENT_TIMEOUT = 24.hours
    HAMMER_ACTION = "hammer".freeze
    I18N_SCOPE = "activerecord.attributes.magic_bean/auction/activity".freeze
    BID_I18N_SCOPE = ["activerecord", "attributes", "magic_bean/auction/bid"].freeze
    END_NOTIFICATION_I18N_SCOPE = [I18N_SCOPE, "notification"].freeze

    # concerns
    include PriceConvertConcern
    include AASM

    # attr related macros
    enum state: {
      draft: 0, # 草稿
      pending: 1, # 已发布但还没开始
      bidding: 2, # 拍卖中
      paying: 3, # 中标且等待付款
      sold: 4, # 成交
      pass: 5, # 流标，没人出价或出价没达到底价
      pay_timeout: 6, # 弃标，中标后超过 24 小时未付款
      direct_buy: 7 # 直接购买
    }, _suffix: true

    # association macros
    belongs_to :store
    belongs_to :category
    belongs_to :minor_category, optional: true, class_name: "MagicBean::Category", foreign_key: "minor_category_id"
    belongs_to :brand
    belongs_to :qa_and_guarantee
    belongs_to :best_bid, class_name: "MagicBean::Auction::Bid", foreign_key: :best_bid_id, optional: true
    belongs_to :best_automatic_bid, class_name: "MagicBean::Auction::AutomaticBid", foreign_key: :best_automatic_bid_id, optional: true
    belongs_to :item, optional: true
    belongs_to :stock_keeping_unit, optional: true
    belongs_to :auction_order, class_name: "MagicBean::AuctionOrder", foreign_key: :order_id, inverse_of: :auction_activity, optional: true

    has_many :bids, -> { order(created_at: :desc) }, class_name: "MagicBean::Auction::Bid", foreign_key: :auction_activity_id, dependent: :destroy
    has_many :automatic_bids, -> { order(amount_limit_in_cent: :desc) }, class_name: "MagicBean::Auction::AutomaticBid", foreign_key: :auction_activity_id, dependent: :destroy
    has_many :auction_activity_participations, class_name: "MagicBean::Auction::ActivityParticipation", foreign_key: :auction_activity_id, dependent: :destroy

    # validation macros
    validates :no, presence: true, uniqueness: true
    validates :cover, presence: true
    validates :main_images, presence: true
    validates :detail_images, presence: true
    validates :start_at, presence: true, timeliness: { before: :default_end_at }
    validates :default_end_at, presence: true, timeliness: { after: lambda { Time.current }, message: "需大于当前时间" }, if: :draft_state?
    validates :starting_price_in_cent, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 999999999 }
    validates :bidding_increments_in_cent, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 999999999 }
    validates :reserve_price_in_cent, numericality: { greater_than: 0, less_than_or_equal_to: 999999999 }, allow_nil: true
    validates :directly_purchase_price_in_cent, numericality: { greater_than: 0, less_than_or_equal_to: 999999999 }, allow_nil: true

    # callbacks
    before_validation :set_no, on: :create
    before_create :set_default_best_bid_amount
    before_save :update_parent_categories, :set_i18n_attributes
    after_create_commit :generate_auction_item_and_sku

    # other macros
    translates :title, :description
    globalize_accessors attributes: [:title, :description]

    convert_price_to_yuan :starting_price_in_cent, :bidding_increments_in_cent,
                          :reserve_price_in_cent, :directly_purchase_price_in_cent,
                          :best_bid_amount_in_cent

    delegate :name, to: :category, prefix: true
    delegate :name, to: :minor_category, prefix: true, allow_nil: true
    delegate :name, to: :brand, prefix: true
    delegate :user_fuzzy_name, to: :best_bid, prefix: true, allow_nil: true
    delegate :image, to: :qa_and_guarantee, prefix: true

    ransacker :state, formatter: proc { |val| states[val] }
    ransack_alias :keyword, :translations_title_or_translations_description

    aasm :state, column: :state, enum: true do
      state :draft, initial: true
      state :pending
      state :bidding
      state :paying
      state :sold
      state :pass
      state :pay_timeout
      state :direct_buy

      event :publish do
        after do
          self.update_columns(publish_at: Time.current, final_end_at: default_end_at)
          UpdateAuctionActivityStateJob.set(wait_until: start_at).perform_later(id, "start")
          UpdateAuctionActivityStateJob.set(wait_until: default_end_at).perform_later(id, HAMMER_ACTION)
        end
        transitions from: :draft, to: :pending
      end

      event :start do
        transitions from: :pending, to: :bidding
      end

      event :hammer do
        transitions from: :bidding, to: :pass do
          guard do
            time_up? ? !can_pay? : false
          end
        end
        transitions from: :bidding, to: :paying do
          guard do
            time_up? && can_pay?
          end
          after do
            winning_auction_participation&.win!
            UpdateAuctionActivityStateJob.set(wait: PAYMENT_TIMEOUT).perform_later(id, "timeout")
          end
        end
        after do
          fail_bidding_activity_participations
          notify_participants_auction_ended
        end
      end

      event :sale do
        transitions from: :paying, to: :sold do
          after do
            winning_auction_participation&.sale!
          end
        end
      end

      event :timeout do
        transitions from: :paying, to: :pay_timeout do
          after do
            winning_auction_participation&.timeout!
          end
        end
      end

      event :pass do
        transitions from: :bidding, to: :pass
      end

      event :direct_buy do
        transitions from: :bidding, to: :direct_buy do
          after do
            self.update_column(:best_bid_amount_in_cent, stock_keeping_unit.price_in_cent)
            fail_bidding_activity_participations
          end
        end
      end
    end

    # scopes
    scope :show_on_app, -> { where(state: [:pending, :bidding]) }

    # class methods

    # instance methods
    def has_reserve_price?
      reserve_price_in_cent.to_i.positive?
    end

    def next_bid_amount_in_cent
      best_bid_amount_in_cent + bidding_increments_in_cent
    end

    def is_increase_mulpitles_of_bidding_increment(amount_in_yuan)
      amount = (amount_in_yuan.to_f * 100).round
      # 出价增额必须为最小出价金额的倍数
      if ((amount - next_bid_amount_in_cent) % bidding_increments_in_cent).zero?
        true
      else
        false
      end
    end

    def add_new_direct_bid(params)
      new_bid = nil
      self.with_lock do
        new_bid = self.bids.new(user: params[:user], member_id: params[:member_id], amount_in_yuan: params[:amount_in_yuan], kind: :direct)
        if best_automatic_bid_id.present? # 1. 当前有自动出价
          # 新的直接出价大于当前最大的自动出价，则先创建自动出价，再保存新的直接出价
          if new_bid.amount_in_cent > best_automatic_bid.amount_limit_in_cent
            ActiveRecord::Base.transaction do
              MagicBean::Auction::Bid.create(
                user_id: best_automatic_bid.user_id,
                member_id: best_automatic_bid.user.member_id,
                auction_activity_id: id,
                amount_in_cent: best_automatic_bid.amount_limit_in_cent,
                kind: :automatic
              )
              update_columns(best_automatic_bid_id: nil)
              new_bid.save
            end
          # 新的直接出价等于当前最大的自动出价时，提示用户出价已存在
          elsif new_bid.amount_in_cent == best_automatic_bid.amount_limit_in_cent
            new_bid.errors.add(:amount_in_cent, I18n.t("errors.taken", scope: MagicBean::Auction::Activity::I18N_SCOPE))
          else
            new_bid.save
          end
        else # 2. 当前没有自动出价
          new_bid.save
        end
      end

      new_bid
    end

    def add_new_automatic_bid!(params)
      new_auto_bid = nil

      self.with_lock do
        new_auto_bid = self.automatic_bids.create!(user_id: params[:user_id], amount_limit_in_yuan: params[:amount_limit_in_yuan])
        if best_automatic_bid.present?
          if new_auto_bid.amount_limit_in_cent > best_automatic_bid.amount_limit_in_cent
            # 如果新的自动出价大于现有的自动出价，则先为现有的自动出价
            # 生成一个出价记录，再为新的自动出价生成一个出价记录
            if best_automatic_bid.amount_limit_in_cent > best_bid_amount_in_cent
              MagicBean::Auction::Bid.create!(
                user_id: best_automatic_bid.user_id,
                member_id: best_automatic_bid.user.member_id,
                auction_activity_id: id,
                amount_in_cent: best_automatic_bid.amount_limit_in_cent,
                kind: :automatic
              )
            end

            self.best_bid_amount_in_cent = best_automatic_bid.amount_limit_in_cent

            MagicBean::Auction::Bid.create!(
              user_id: new_auto_bid.user_id,
              member_id: new_auto_bid.user.member_id,
              auction_activity_id: id,
              amount_in_cent: next_bid_amount_in_cent,
              kind: :automatic
            )
            self.update! best_automatic_bid: new_auto_bid
          else
            # 新的自动出价小于现有的最大自动出价，则先为新的自动出价生成一个出价记录，
            # 再在其基础上为当前最大自动出价生成一个出价记录
            MagicBean::Auction::Bid.create!(
              user_id: new_auto_bid.user_id,
              member_id: new_auto_bid.user.member_id,
              auction_activity_id: id,
              amount_in_cent: new_auto_bid.amount_limit_in_cent,
              kind: :automatic
            )

            self.best_bid_amount_in_cent = new_auto_bid.amount_limit_in_cent

            MagicBean::Auction::Bid.create!(
              user_id: best_automatic_bid.user_id,
              member_id: best_automatic_bid.user.member_id,
              auction_activity_id: id,
              amount_in_cent: next_bid_amount_in_cent,
              kind: :automatic
            )
          end
        else
          MagicBean::Auction::Bid.create!(
            user_id: new_auto_bid.user_id,
            member_id: new_auto_bid.user.member_id,
            auction_activity_id: id,
            amount_in_cent: next_bid_amount_in_cent,
            kind: :automatic
          )
          self.update! best_automatic_bid: new_auto_bid
        end
      end
      new_auto_bid
    end

    def should_renew_final_end_at?
      # 拍賣結束時間半小時前，有人出價，結束時間自動延長半小時
      auto_renewal_end_at? && ((final_end_at - Time.current) <= AUTO_RENEWAL_END_AT_INTERVAL)
    end

    def check_and_enqueue_hammer_job
      return unless should_renew_final_end_at?

      new_end_at = final_end_at + AUTO_RENEWAL_END_AT_INTERVAL
      self.update_attribute :final_end_at, new_end_at
      UpdateAuctionActivityStateJob.set(wait_until: new_end_at).perform_later(id, "hammer")
    end

    # 拍賣結束且有得標者(最高出價者且高於底價(如果有底價的話))
    def can_pay?
      return false if best_bid_id.blank?

      return false if reserve_price_in_cent.present? && (reserve_price_in_cent > best_bid_amount_in_cent)

      true
    end

    def time_up?
      Time.current >= final_end_at
    end

    def generate_auction_item_and_sku
      return item if item_id.present?

      uuid = get_sku_no_and_barcode

      new_item = MagicBean::Item.new(
        title_en: title_en,
        title_zh_cn: title_zh_cn,
        title_zh_tw: title_zh_tw,
        description_en: description_en,
        description_zh_cn: description_zh_cn,
        description_zh_tw: description_zh_tw,
        item_type: :auction,
        listing_type: :pending,
        category_id: category_id,
        minor_category_id: minor_category_id,
        main_images: main_images,
        detail_images: detail_images,
        brand_id: brand_id,
        qa_and_guarantee_id: qa_and_guarantee_id,
        cover: cover,
        store_id: store_id,
        quantity: 1,
        channels: [:app],
        is_virtual: true,
        storage_method: :blank_storage,
        product_attributes: {
          store_id: store_id,
          title: title_zh_cn,
          sub_title: title_en,
          description: description_zh_cn,
          cover: cover,
          category_id: category_id,
          minor_category_id: minor_category_id,
          brand_id: brand_id,
          detail_images: detail_images,
          main_images: main_images,
          qa_and_guarantee_id: qa_and_guarantee_id,
        },
        stock_keeping_units_attributes: [{
          properties: default_sku_properties,
          no: uuid,
          barcode: uuid,
          quantity: 1,
          price_in_cent: starting_price_in_cent, # 起拍价作为初始售价
          on_sale: false,
          store_id: store_id,
          marketing_mode: :self_support,
          image: cover
        }]
      )

      new_item.save
      sku_id = new_item.stock_keeping_units.first.id

      self.update_columns item_id: new_item.id, stock_keeping_unit_id: sku_id

      new_item
    end

    def refresh_sku_price(is_direct_buy)
      new_price = is_direct_buy ? directly_purchase_price_in_cent : best_bid_amount_in_cent

      item.update_attribute :price_in_cent, new_price
      stock_keeping_unit.update_attribute :price_in_cent, new_price
    end

    def notify_participants_new_bid(excluded_user_id, new_amount_in_cent)
      participation_user_ids = auction_activity_participations.where.not(user_id: excluded_user_id).pluck(:user_id)
      not_notify_user_ids = automatic_bids.ransack(user_id_not_eq: excluded_user_id, amount_limit_in_cent_gt: new_amount_in_cent).result.pluck(:user_id)
      user_ids = participation_user_ids - not_notify_user_ids

      return if user_ids.empty?

      original_locale = I18n.locale
      I18n.available_locales.each do |locale|
        I18n.locale = locale
        heading = I18n.t(:notification_title, scope: BID_I18N_SCOPE)
        content = I18n.t(:notification_content, title: title_of_notification_content, scope: BID_I18N_SCOPE)
        to_user_ids = MagicBean::User.where(id: user_ids, locale: locale).pluck(:id)

        next if to_user_ids.empty?

        to_user_ids.each do |user_id|
          MagicBean::AppTextMessage.create(
            user_id: user_id, title: heading, content: content,
            kind: :customer_service, target_type: model_name.to_s, target_id: id
          )
        end
      end

      I18n.locale = original_locale
    end

    def notify_participants_auction_ended
      user_ids = auction_activity_participations.pluck(:user_id)

      return if user_ids.empty?

      original_locale = I18n.locale

      I18n.available_locales.each do |locale|
        I18n.locale = locale
        heading = I18n.t(:end_title, scope: END_NOTIFICATION_I18N_SCOPE)
        end_word = if paying_state? || direct_buy_state?
                     I18n.t(:end_success_word, scope: END_NOTIFICATION_I18N_SCOPE)
                   elsif pass_state?
                     I18n.t(:end_failure_word, scope: END_NOTIFICATION_I18N_SCOPE)
                   end
        content = I18n.t(:end_content, title: title_of_notification_content, word: end_word, scope: END_NOTIFICATION_I18N_SCOPE)
        to_user_ids = MagicBean::User.where(id: user_ids, locale: locale).pluck(:id)

        next if to_user_ids.empty?

        to_user_ids.each do |user_id|
          MagicBean::AppTextMessage.create(
            user_id: user_id, title: heading, content: content,
            kind: :customer_service, target_type: model_name.to_s, target_id: id
          )
        end
      end

      I18n.locale = original_locale
    end

    def app_path
      @app_path ||= { type: "auction", params: { id: id } }.to_json
    end

    def mini_program_path ; end

    def fail_bidding_activity_participations
      auction_activity_participations.bidding.update_all(state: :failed)
    end

    def winning_auction_participation
      @winning_auction_participation ||= auction_activity_participations.find_by(user_id: best_bid.user_id)
    end

    def title_of_notification_content
      @title_of_notification_content ||= "\"#{title&.truncate(20)}\""
    end

    def can_edit?
      draft_state?
    end

    def destroyable?
      state.in? %w[draft pending]
    end

    private

    def update_parent_categories
      if category_id_changed?
        self.parent_category_id = category.parent_id
      end

      if minor_category_id_changed?
        self.minor_parent_category_id = minor_category.parent_id
      end
    end

    def default_sku_properties
      Rails.env.production? ? "1383:5524" : "37:94" # `规格:一件` 对应的值
    end

    def set_no
      loop do
        self.no = Time.now.strftime("%Y%m%d%H%M%L") + rand.to_s[2..4]
        break unless self.class.exists?(no: no)
      end
    end

    def get_sku_no_and_barcode
      loop do
        uuid = SecureRandom.uuid
        return uuid unless (MagicBean::StockKeepingUnit.exists?(no: uuid) || MagicBean::StockKeepingUnit.exists?(barcode: uuid))
      end
    end

    def set_i18n_attributes
      %w[title description].each do |attr|
        text_zh_cn = send("#{attr}_zh_cn")
        if text_zh_cn.present?
          self.send("#{attr}_zh_tw=", Ropencc.conv("s2tw.json", text_zh_cn)) if send("#{attr}_zh_tw").blank?
          self.send("#{attr}_en=", EasyTranslate.translate(text_zh_cn, from: :"zh-CN", to: :en)) if send("#{attr}_en").blank?
        end
      end
    end

    def set_default_best_bid_amount
      self.best_bid_amount_in_cent = starting_price_in_cent
    end
  end
end
