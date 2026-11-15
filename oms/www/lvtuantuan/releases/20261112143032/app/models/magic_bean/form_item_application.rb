# frozen_string_literal: true

module MagicBean
  class FormItemApplication < ApplicationRecord
    enum channel: {
      mini_program: 1,
      app: 2,
      web: 3
    }

    APPLY_PROPERTIES = %w[name email mobile birthday address remark]

    belongs_to :user
    belongs_to :form_item
    belongs_to :store

    # validation macros
    validates_presence_of :apply_properties
    validate :check_item_channel, on: :create

    # other macros
    delegate :name, to: :store, prefix: true

    APPLY_PROPERTIES.each do |attr_name|
      perfix_attr_name = "apply_#{attr_name}"
      define_method perfix_attr_name do
        @perfix_attr_name = apply_properties&.dig(attr_name)&.strip
      end
    end

    # callbacks
    after_create_commit :new_application_notification

    private
    def check_item_channel
      errors[:base] << I18n.t("error.order.sale_channel", sku_title: form_item.title, channel: form_item.channels_text) unless form_item.channel_match?(channel)
    end

    def new_application_notification
      emails = form_item.notification_emails&.split(/[;；]/)&.map(&:strip)
      FormItemMailer.with(form_item_application: self, emails: emails).new_application.deliver_later if emails.present?
    end
  end
end
