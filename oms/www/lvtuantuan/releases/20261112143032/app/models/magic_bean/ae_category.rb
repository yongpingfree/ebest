# frozen_string_literal: true

# 注意: 这个表是用来存速卖通跨境站点的分类，不是海外站点的分类，海外站点对应drop_shipper（eBest称为跨境购），其数据存在category表
class MagicBean::AeCategory < ApplicationRecord
  validates :name, presence: true
  validates :ae_id, presence: true, uniqueness: true

  has_many :items, class_name: "MagicBean::Item", primary_key: "ae_id", foreign_key: "ae_category_id", dependent: :nullify
end
