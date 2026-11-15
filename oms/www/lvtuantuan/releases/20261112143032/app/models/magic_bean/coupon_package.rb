# frozen_string_literal: true
module MagicBean
  class CouponPackage < ApplicationRecord
    include GenerateCodeConcern
    include Redis::Objects

    # scope
    scope :active, -> { published.where(":time BETWEEN start_at AND end_at", {time: Time.current}) }

    # constants

    # attr related macros
    enum status: { pending: 1, published: 2}
    enum user_kind: { member: 1, new_users: 2, normal: 3 }

    set :collected_user_ids

    # association macros
    has_and_belongs_to_many :users
    belongs_to :store, optional: true

    # validation macros
    validates_presence_of :user_kind, :cover, :coupon_template_ids
    validate :check_start_at_and_end_at_valid
    validate :check_coupon_templates_user_kind_valid
    validate :coupon_templates_not_inlcude_random_reduction

    # callbacks
    before_create :generate_code
    after_commit :enqueue_clean_collected_user_ids_data, if: :saved_change_to_end_at?
    before_validation :remove_blank_value_from_ids

    # other macros

    def active?
      published? && Time.current.between?(start_at, end_at)
    end

    def coupon_count
      coupon_template_ids.size
    end

    def coupon_templates
      @coupon_templates ||= MagicBean::CouponTemplate.where(id: coupon_template_ids)
    end

    def coupon_templates_info
      coupon_templates.map { |coupon_template| { id: coupon_template.id, title: coupon_template.title } }
    end

    def toggle_state
      target_state = published? ? "pending" : "published"

      update(status: target_state)
    end

    def assign_coupon_template(user)

      unless Time.current.between?(start_at, end_at)
        errors.add(:base, I18n.t("error.coupon_package.expired"))
        return false
      end

      if could_be_received_by?(user)
        if collected_user_ids.add(user.id)
          self.users << user
          GenerateCouponsForPackageJob.perform_later(id, user.id)
          return true
        else
          errors.add(:base, I18n.t("error.coupon_package.already_in_your_account"))
        end
      else
        errors.add(:base, I18n.t("error.coupon_package.not_eligible"))
      end
      return false if errors.any?
    end

    def mini_program_path
      "pages/coupon/coupon-package/coupon-package?code=#{code}"
    end

    def app_path
      { type: "couponPackage", params: { code: code } }.to_json
    end

    private

    def could_be_received_by?(user)
      return case user_kind
        when "member"
          user.member.present?
        when "new_users"
          user.new_user?
        when "normal"
          true # normal类型的优惠券礼包所有能进入领取页面的用户都可以领取
        else
          false
        end
    end

    def enqueue_clean_collected_user_ids_data
      CleanCouponPackageCollectedUserJob.set(wait_until: end_at).perform_later(id)
    end

    def remove_blank_value_from_ids
      coupon_template_ids.select!(&:present?)
    end

    def check_start_at_and_end_at_valid
      errors.add(:base, I18n.t("errors.messages.start_at_can_not_later_than_end_at")) if start_at && end_at && start_at > end_at
    end

    def check_coupon_templates_user_kind_valid
      if !member? && coupon_templates.any? { |coupon_template| coupon_template.member? }
        errors.add(:base, I18n.t("error.coupon_package.can_not_contain_memerb_coupon"))
      end
    end

    def coupon_templates_not_inlcude_random_reduction
      if coupon_templates.exists?(kind: :random_reduction)
        self.errors.add(:base, I18n.t("error.coupon_package.random_discount_can_not_be_associated"))
      end
    end
  end
end
