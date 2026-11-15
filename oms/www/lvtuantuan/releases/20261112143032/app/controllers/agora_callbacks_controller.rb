# frozen_string_literal: true

class AgoraCallbacksController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_signature!

  @@agora_callbacks_logger = ::Logger.new("./log/agora_callbacks.log")

  # 融合 CDN 直播事件回调: https://docportal.shengwang.cn/cn/fusion-cdn-streaming/event-fls?platform=RESTful
  # 不支持的逻辑处理统一返回 200 状态码，避免 Agora 重试。
  def index
    @@agora_callbacks_logger.debug("Agora Callbacks body: #{params}")

    # 目前只处理录制文件生成事件。
    render json: { message: "Unsupported Event Type" } and return unless agora_params[:eventType].to_i == 101

    live_room_id = if Rails.env.production?
                     agora_params.dig(:payload, :streamName)
                   else
                     agora_params.dig(:payload, :streamName).to_s.from(4) # 除了 production 环境，其他环境的 streamName 都是 "TEST" 开头后接 ID
                   end
    live_room = MagicBean::LiveRoom.find_by(id: live_room_id)

    render json: { message:  "Stream Not Found" } and return if live_room.nil?

    filename = params.dig(:payload, :fileName).to_s
    if filename.ends_with?(".mp4") # mp4 格式长视频会被切片成多个文件回调
      live_room.agora_mp4_filenames << filename
      live_room.save
    elsif filename.ends_with?(".m3u8")
      live_room.update(agora_vod_filename: filename)
    end

    render json: { message: "OK" }
  end

  private

  # 验证签名: https://docportal.shengwang.cn/cn/fusion-cdn-streaming/signature_verify?platform=RESTful
  def verify_signature!
    hmac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), MagicBean::LiveRoom::LIVE_CALLBACK_SECRET, request.raw_post)

    return true if hmac == signature

    @@agora_callbacks_logger.debug("Agora Callbacks signature: #{signature}")

    render json: { error: "Invalid Signature" }, status: :bad_request
  end

  def signature
    request.headers["Agora-Signature-V2"]
  end

  def agora_params
    params.permit(:eventType, :noticeId, :notifyMs, :productId, payload: {})
  end
end
