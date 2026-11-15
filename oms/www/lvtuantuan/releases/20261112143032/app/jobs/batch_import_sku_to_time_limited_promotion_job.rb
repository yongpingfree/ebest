# frozen_string_literal: true

class BatchImportSkuToTimeLimitedPromotionJob < ApplicationJob
  queue_as :default

  def perform(promotion_id, file_url, admin_user_id)
    promotion = MagicBean::TimeLimitedPromotion.find_by(id: promotion_id)

    promotion.import_from_excel_and_notify(file_url, admin_user_id) if promotion.present?
  end
end
