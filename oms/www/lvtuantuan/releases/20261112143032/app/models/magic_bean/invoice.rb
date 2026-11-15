# frozen_string_literal: true

module MagicBean
  class Invoice < ApplicationRecord
    # constants
    ENG_NAME_REGEX = /\A[\s\w_\-·]+\z/
    VALIDATION_FORMAT_SCOPE = ["activerecord", "attributes", "magic_bean/invoice", "errors", "format"].freeze

    # concerns

    # attr related macros
    enum kind: { individual: 1, company: 2 }

    # association macros
    belongs_to :user

    # validation macros
    validates :first_name, presence: true, format: { with: ENG_NAME_REGEX, message: I18n.t("contains_only_english_or_dash_or_middot", scope: VALIDATION_FORMAT_SCOPE, locale: I18n.locale) }
    validates :last_name, presence: true, format: { with: ENG_NAME_REGEX, message: I18n.t("contains_only_english_or_dash_or_middot", scope: VALIDATION_FORMAT_SCOPE, locale: I18n.locale) }
    validates :email, presence: true, format: { with: AdminUser::EMAIL_PATTERN, allow_blank: true }
    validates :kind, presence: true
    validate :check_tel_number_format, if: :tel_number?

    # callbacks
    before_validation :format_tel_number
    before_save :set_self_default, if: :should_set_default?
    after_save :check_default_unique, if: :is_default?
    after_commit :set_other_default, on: :destroy, if: :is_default?

    # other macros

    # scopes

    # class methods

    # instance methods
    protected

    def check_tel_number_format
      errors.add(:base, I18n.t("error.mobile.invalid_format")) unless Phony.plausible?(tel_number)
    end

    def format_tel_number
      self.tel_number = tel_number&.gsub(" ", "")
    end

    def name
      "#{first_name} #{last_name}"
    end

    # 当前没有默认发票时，新建时设置为默认发票
    def should_set_default?
      !is_default && user.invoices.where(is_default: true).empty?
    end

    def set_self_default
      self.is_default = true
    end

    # 删除了默认发票后自动设置最新的为默认发票
    def set_other_default
      user.invoices.order(created_at: :desc)
        .first&.update(is_default: true)
    end

    # 更新为默认发票时，将其他默认发票置为 false
    def check_default_unique
      invoices = user.invoices
        .where.not(id: self.id)
        .where(is_default: true)

      invoices.update_all(is_default: false) if invoices.any?
    end
  end
end
