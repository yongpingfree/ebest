# frozen_string_literal: true

class MagicBean::HomepagePagingSetting < ApplicationRecord
  belongs_to :custom_page
  belongs_to :store

  validates :name, :image, :selected_image, :position, :background_image, presence: true
end
