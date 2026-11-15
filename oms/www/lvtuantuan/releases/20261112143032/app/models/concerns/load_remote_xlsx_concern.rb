# frozen_string_literal: true

module LoadRemoteXlsxConcern
  extend ActiveSupport::Concern

  class_methods do
    def try_load_remote_file(file_url)
      unsupported_file_message = "不支持的文件格式，请上传 xlsx 格式文件"
      # file_url 只应来自管理端 aws_upload!，白名单外地址（含 file://、内网地址）一律拒绝，防 SSRF
      return [nil, "文件地址不受支持，请通过后台上传后导入"] unless Validators::ResourceUrl.valid_file_url?(file_url)

      if File.extname(file_url) != ".xlsx"
        return [nil, unsupported_file_message]
      end

      begin
        xlsx = Roo::Spreadsheet.open(file_url, extension: :xlsx)
      rescue Zip::Error
        return [nil, unsupported_file_message]
      end

      [xlsx, nil]
    end
  end
end
