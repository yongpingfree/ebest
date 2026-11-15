# frozen_string_literal: true

class BatchAssignCouponMailer < ApplicationMailer
  def export(coupon_template, success_mobiles, failed_mobiles, email)
    return if email.blank?

    @success_mobiles = success_mobiles
    @failed_mobiles = failed_mobiles

    @subject = "#{coupon_template.title}批量分配优惠券结果-#{Time.current.strftime("%Y-%m-%d-%H-%M")}"
    mail(
      to: email,
      subject: @subject
    )
  end
end
