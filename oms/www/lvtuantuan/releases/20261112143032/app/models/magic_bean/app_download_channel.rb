# frozen_string_literal: true
require "prawn/qrcode"

class MagicBean::AppDownloadChannel < ApplicationRecord
  include GenerateCodeConcern
  include FileUploadConcern

  # scope

  # constants

  # attr related macros

  # association macros

  # validation macros

  # callbacks
  before_create :generate_code
  after_commit :generate_qrcode, on: :create

  # other macros

  def generate_qrcode(link = nil)
    qrcode_link = link || "#{Rails.application.credentials.dig(Rails.env.to_sym, :domain)}/app_download_channels/#{self.id}"
    file = RQRCode::QRCode.new(qrcode_link).as_png(size: 300)

    filename = SecureRandom.hex(5)[0..8]
    path = File.join Rails.root, "public", "uploads", "qrcodes", filename
    dir = File.dirname(path)
    FileUtils.mkdir_p(dir) unless File.directory?(dir)

    File.open(path, "wb") { |f| f.write(file) }
    self.qrcode = aws_upload!(path)
    FileUtils.rm path

    self.save
  end
end
