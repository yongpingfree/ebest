# frozen_string_literal: true

module QrcodeConcern
  extend ActiveSupport::Concern

  private

  def enqueue_generate_qrcode_job(width = 460)
    GenerateQrcodeJob.perform_later(self.class.name, id, width)
  end

  def generate_qrcode(width = 460)
    # 小程序码的 path 不能有最前面的 `/`
    response = WechatAus::Api.get_mini_program_qrcode(qrcode_params[:sence],
                                                      qrcode_params[:path],
                                                      width,
                                                      true,
                                                      false)
    if response[:status] == "success"

      filename = SecureRandom.hex(5)[0..8]
      path = File.join Rails.root, "public", "uploads", "qrcodes", filename
      dir = File.dirname(path)
      FileUtils.mkdir_p(dir) unless File.directory?(dir)

      File.open(path, "wb") { |f| f.write(response[:file]) }

      if self.class.name == "MagicBean::CustomPage"
        self.qrcode_url = aws_upload!(path)
      else
        self.qrcode = aws_upload!(path)
      end

      FileUtils.rm path

      self.is_aus_qrcode = true
      self.save
    else
      raise "ID[#{id}] #{title}: #{response[:message]}"
    end
  end
end
