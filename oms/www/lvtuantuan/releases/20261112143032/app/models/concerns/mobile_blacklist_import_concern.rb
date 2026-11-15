# frozen_string_literal: true

module MobileBlacklistImportConcern
  extend ActiveSupport::Concern

  include LoadRemoteXlsxConcern
  EXCEL_FIELDS = %w[mobile enabled live_comment_disabled live_lottery_disabled order_disabled started_at ended_at]

  class_methods do
    def import_from_excel_and_notify(file_url, admin_user_id)
      admin_user = MagicBean::AdminUser.find admin_user_id
      result = import_data_from_excel(file_url, admin_user)
      ExcelImportMailer.notify_admin_user(admin_user.email, "直播用户黑名单导入结果", result).deliver_later
      Aws::CustomOss.delete_file(file_url)
    end

    def import_data_from_excel(file_url, admin_user)
      xlsx, unsupported_file_message = try_load_remote_file(file_url)

      if xlsx.nil? && unsupported_file_message.present?
        return [unsupported_file_message]
      end

      error_messages = []
      processed_count = 0
      skip_row_offset = 2
      result = xlsx.sheet(0).parse(headers: true)

      result[skip_row_offset..-1].each.with_index(skip_row_offset + 1) do |row, idx|
        mobile = row["mobile"].to_s.strip

        break if mobile.blank?

        processed_count += 1

        params = process_row(row)

        blacklist = MagicBean::MobileBlacklist.find_or_initialize_by(mobile: mobile)
        blacklist.assign_attributes(params)

        begin
          if !blacklist.save
            error_messages << "第#{idx}行：#{blacklist.errors.full_messages.join('; ')}"
          end
        rescue ActiveRecord::StatementInvalid
          error_messages << "第#{idx}行：无法处理对单元格数据，请联系技术人员检查"
        end
      end

      {
        processed_count: processed_count,
        error_messages: error_messages
      }
    end

    def process_row(hash)
      row = ActiveSupport::HashWithIndifferentAccess.new(hash)

      # boolean fields
      [:enabled, :live_comment_disabled, :live_lottery_disabled, :order_disabled].each do |key|
        row[key] = get_boolean_value(row[key])
      end

      row.slice(*EXCEL_FIELDS).compact
    end

    def get_boolean_value(value_cn)
      str = value_cn.to_s.strip

      case str
      when "是"
        true
      when "否"
        false
      else
        nil
      end
    end
  end
end
