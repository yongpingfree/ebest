# frozen_string_literal: true

# App 内的订单追踪和客服通知消息 model
module MagicBean
  class AppTextMessage < ApplicationRecord
    # constants
    EXCEL_KIND_MAPPING = {
      "订单追踪" => "order_tracking",
      "客服通知" => "customer_service"
    }
    EXCEL_DATA_COLUMN_LENGTH = 5

    # concerns

    # attr related macros
    enum kind: { order_tracking: 0, customer_service: 1, sku_in_stock: 2 }
    ransacker :kind, formatter: proc { |val| kinds[val] }
    alias_attribute :push_at, :created_at

    # association macros
    belongs_to :user
    belongs_to :admin_user, optional: true

    # validation macros
    validates :title, presence: true
    validates :content, presence: true
    validates :kind, presence: true
    validates :target_type, inclusion: { in: %w(MagicBean::Item MagicBean::CustomPage MagicBean::Auction::Activity) }, allow_blank: true

    # callbacks
    after_create_commit :notify_user, :increase_unread_count
    after_destroy :decrement_unread_count

    # other macros

    # scopes

    # class methods
    class << self
      def batch_notify(file_url, operator)
        failure_records = []
        xlsx = Roo::Spreadsheet.open file_url
        sheet = xlsx.sheet 0

        return unless excel_headers_valid?(sheet.row(1))

        processed_count = 0

        sheet.each_row_streaming(offset: 1) do |row|
          empty_row = false
          if row.respond_to?(:empty?) && row.empty?
            empty_row = true
          end
          EXCEL_DATA_COLUMN_LENGTH.times do |idx|
            if row[idx].nil? || (row[idx].respond_to?(:empty?) && row[idx].empty?)
              empty_row = true
              break
            end
          end

          break if empty_row

          mobile, user_locale, title, cn_kind, content = row[0].value.to_i.to_s, locale_translate(row[1].value.strip), row[2].value.strip, row[3].value.strip, row[4].value.strip

          member = MagicBean::Member.find_by mobile: mobile
          if member.nil?
            failure_records.push({ mobile: mobile, error_message: "没有该客户手机号"})
            next
          end

          kind = EXCEL_KIND_MAPPING[cn_kind]
          if kind.nil?
            failure_records.push({ mobile: mobile, error_message: "#{cn_kind}类型不是“客服通知”或“订单追踪”之一" })
            next
          end

          # 检查用户语系是否跟导入的语系一致
          if user_locale != member.user.locale
            failure_records.push({ mobile: mobile, error_message: "用户语系不一致" })
            next
          end

          processed_count += 1

          msg = MagicBean::AppTextMessage.new(
            user: member.user,
            title: title,
            kind: kind,
            content: content,
            admin_user_id: operator.id
          )

          unless msg.save
            failure_records.push({ mobile: mobile, error_message: msg.errors.full_messages.join("；")})
          end
        end

        AppTextMessageMailer.notify_admin_user(operator.email, failure_records, processed_count).deliver_later
      end

      def excel_headers_valid?(row)
        if row[0].start_with?("客户手机号") &&
          row[1].start_with?("用户语系") &&
          row[2].start_with?("消息标题") &&
          row[3].start_with?("消息类型") &&
          row[4].start_with?("消息内容")
          true
        else
          false
        end
      end

      def locale_translate(locale_str)
        case locale_str
        when "简体中文"
          "zh-CN"
        when "繁体中文"
          "zh-TW"
        when "英文"
          "en"
        end
      end
    end

    # instance methods
    def is_read
      !!read_at
    end

    def read
      unless is_read
        touch(:read_at)
        user.message_unread_counter.decrement!("#{kind}_count")
      end

      self
    end

    def app_path
      { type: "appTextMessage", params: { id: id } }.to_json
    end

    def mini_program_path
      "pages/mine/push-message/detail/index?id=#{id}&type=appTextMessage"
    end

    def target
      @target ||= if target_type.present? && target_id.present?
                    # 新人介绍信归到服务通知
                    if sku_in_stock? || customer_service?
                      target_type.constantize.find_by(id: target_id) || self
                    else
                      # 订单追踪暂时没有跳转
                      self
                    end
                  else
                    self
                  end
    end

    def target_app_path
      @target_path ||= target.app_path
    end

    def target_mini_program_path
      @target_mini_program_path ||= (sku_in_stock? ? target.mini_program_path : nil)
    end

    def notify_user
      AppNotifier.enqueue_app_push_job(title, content, user_id, app_link: target_app_path)
    end

    def increase_unread_count
      (user.message_unread_counter || user.send(:init_message_unread_counter)).increment!("#{kind}_count")
    end

    def decrement_unread_count
      user.message_unread_counter.decrement!("#{kind}_count") unless is_read
    end
  end
end
