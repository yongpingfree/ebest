# frozen_string_literal: true

module MagicBean
  class LiveRoomLotteryWinningUser < ApplicationRecord
    # constants
    RECEIVER_PROPERTIES = %w[id city_name tel_number pure_detail_info detail_info postal_code province_name street_number street first_name last_name unit_number]

    # concerns

    # attr related macros

    # association macros
    belongs_to :live_room_lottery
    belongs_to :user
    belongs_to :live_room

    # validation macros

    # callbacks
    before_save :set_receiver_properties

    # other macros
    delegate :fuzzy_name, :nickname, :member_mobile, to: :user, prefix: true

    # scopes

    # class methods

    # instance methods
    RECEIVER_PROPERTIES.each do |attr_name|
      perfix_attr_name = "receiver_#{attr_name}"
      define_method perfix_attr_name do
        @perfix_attr_name = receiver_properties&.dig(attr_name)&.strip
      end
    end

    def human_receiver_properties
      return nil if receiver_properties.nil?
      "#{receiver_name} #{receiver_tel_number}\n#{full_receiver_address}"
    end

    def full_receiver_address
      return nil if receiver_properties.nil?
      "#{receiver_detail_info} #{receiver_city_name} #{receiver_province_name} #{receiver_postal_code}"
    end

    def receiver_name
      "#{receiver_first_name} #{receiver_last_name}"
    end

    private

    def set_receiver_properties
      address = user.addresses.find_by(id: address_id)
      return if address.nil?

      self.receiver_properties = address.to_order_json
    end
  end
end
