# frozen_string_literal: true

module MagicBean
  class ItemBanner < ApplicationRecord
    # constants

    # concerns

    # attr related macros

    # scopes
    scope :active, -> { where(enabled: true).where("start_at <= ? AND end_at > ?", Time.current, Time.current) }
    scope :valid, -> { where("end_at > ?", Time.current) }

    # association macros
    has_many :item_banner_clicks

    # validation macros
    validates_presence_of :title, :banner, :start_at, :end_at, :enabled, :path, :enabled

    # callbacks

    # other macros

    def items
      MagicBean::Item.includes(:store).where(id: item_ids)
    end

    def path_name
      JSON.parse(path)["name"] if path.present?
    rescue JSON::ParserError
      nil
    end
  end
end
