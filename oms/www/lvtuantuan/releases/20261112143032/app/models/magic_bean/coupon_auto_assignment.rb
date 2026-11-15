# frozen_string_literal: true

module MagicBean
  class CouponAutoAssignment < ApplicationRecord

    acts_as_paranoid

    enum assign_type: { everyone: 0, part: 1 }

    validates_presence_of :start_date, :end_date, :assign_type, :coupon_template_ids
    validates :assign_user_ids, presence: true, if: :part?
    validate :check_assign_date, on: :create
    validate :coupon_templates_not_inlcude_random_reduction

    before_save :empty_assign_user_ids, if: :everyone?
    after_create :enqueue_auto_assign_coupon_job

    ransacker :assign_type, formatter: proc { |v| assign_types[v] }

    def assign_users
      @assign_users ||= User.where(id: assign_user_ids)
    end

    def coupon_templates
      @coupon_templates ||= CouponTemplate.where(id: coupon_template_ids)
    end

    def assign_coupons_to_user!(user)
      transaction do
        coupon_templates.each do |coupon_template|
          coupon = coupon_template.generate_coupons[0]

          coupon.assign_to_user(user)
        end
      end
    end

    def batch_assign_coupons_to_users!(user_ids)
      transaction do
        coupon_templates.each do |coupon_template|
          coupon_template.generate_coupons_and_assign_to_users(user_ids)
        end
      end
    end

    private

    def check_assign_date
      if start_date && end_date
        errors.add(:base, "开始日期不能小于当前日期") if start_date < Date.current
        errors.add(:base, "开始日期不能大于结束日期") if start_date > end_date
        errors.add(:base, "结束日期需大于当前日期") if end_date <= Date.current
      end
    end

    def enqueue_auto_assign_coupon_job
      wait_until = if Time.current < start_date.beginning_of_day + 1.hour
                     start_date + 1.hour
                   else
                     start_date + 25.hours
                   end

      AutoAssignCouponsJob.set(wait_until: wait_until).perform_later(id)
    end

    def empty_assign_user_ids
      self.assign_user_ids = []
    end

    def coupon_templates_not_inlcude_random_reduction
      if coupon_templates.exists?(kind: :random_reduction)
        self.errors.add(:base, "不能关联随机满减券")
      end
    end
  end
end
