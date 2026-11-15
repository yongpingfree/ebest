# frozen_string_literal: true

class MagicBean::OperationRecord < ApplicationRecord

  acts_as_paranoid

  belongs_to :admin_user, optional: true
  belongs_to :operatable, polymorphic: true, optional: true

  enum channel: {
    admin: 1,
    wms: 2
  }

  validates_presence_of :content

  def operatable_title
    return if operatable_type.in?(["MagicBean::PaymentSetting"])
    operatable&.title
  end

  def human_channel
    @human_channel ||= (admin? ? "OMS" : "中台WMS")
  end
end
