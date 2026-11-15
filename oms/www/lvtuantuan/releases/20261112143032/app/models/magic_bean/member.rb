# frozen_string_literal: true
module MagicBean
  class Member < ApplicationRecord
    # scope

    # constants
    INVITE_CODE_LENGTH = 6
    MAX_LOGIN_TRY = 5

    # attr related macros
    # 来源
    enum channel: {
      mini_program: 1,
      app: 2,
      web: 3
    }

    # association macros
    belongs_to :user, inverse_of: :member
    belongs_to :inviter, class_name: "MagicBean::Member", optional: true
    has_many :invitees, class_name: "MagicBean::Member", foreign_key: :inviter_id
    has_many :integral_records, dependent: :destroy
    with_options class_name: "MagicBean::IntegralRecord", dependent: :destroy do
      has_many :sign_up_integral_records, -> { sign_up }
      has_many :inviting_integral_records, -> { inviting }
      has_many :spent_integral_records, -> { spent }
    end

    # validation macros
    validates :mobile, presence: true, uniqueness: true, format: { with: /\A\d{11}\z/ }
    validates :email, uniqueness: true, format: { with: /\A.+@.+\z/ }, allow_nil: true
    validates :user, presence: true
    validates_associated :user, message: lambda { |_, user| user[:value].errors.full_messages.first }
    validates :available_integral, numericality: { greater_than_or_equal_to: 0 }
    validates :blocked_integral, numericality: { greater_than_or_equal_to: 0 }
    validates :cumulative_integral, numericality: { greater_than_or_equal_to: 0 }
    validates :app_available_integral, numericality: { greater_than_or_equal_to: 0 }
    validates :app_blocked_integral, numericality: { greater_than_or_equal_to: 0 }
    validates :app_cumulative_integral, numericality: { greater_than_or_equal_to: 0 }
    validates :email_confirmation_token, uniqueness: true, allow_nil: true
    before_validation :set_channel, :format_email
    validate :check_birthday, on: :update, if: :birthday_changed?

    # callbacks
    before_create :generate_invite_code, :set_names, :generate_confirmation_token
    after_commit :sign_up_reward, :assign_newbie_coupon, :enqueue_confirmation_email, on: :create
    after_save :assign_invited_coupon, if: :saved_change_to_inviter_id?
    after_save :check_user_info_finished, if: -> { saved_change_to_email? || saved_change_to_birthday? }
    after_commit :set_can_edit_birthday, :enqueue_reward_birthday_job, if: :saved_change_to_birthday?
    # after_save :sync_contact_to_sendgrid, if: -> { saved_change_to_email? || saved_change_to_receive_activity_email? }

    # other macros
    delegate :nickname, :sign_up_channel, to: :user
    delegate :nickname, to: :inviter, prefix: true, allow_nil: true

    def create_integral_record(kind, targetable, channel, amount = 0)
      integral_record_json = MagicBean::IntegralRecord.rules(amount.to_i)[kind].merge(targetable: targetable)
      integral_records.create(integral_record_json.merge(channel: channel)) if integral_record_json[:integral] != 0
    end

    def rebase_other_member(member)
      ActiveRecord::Base.transaction do
        member_info = member.as_json(except: [:id, :created_at, :updated_at, :mobile, :user_id])
        member.integral_records.update_all(member_id: id)
        member.destroy!
        update!(member_info)
      end
    end

    def enqueue_confirmation_email
      return if email_confirmed?

      if email_confirmation_token.blank?
        generate_confirmation_token
        save
      end

      SendKlaviyoEmailJob.perform_later(self.class.model_name.name, id, "send_confirmation_email")
    end

    def email_confirmation_url
      "#{Rails.application.credentials.dig(Rails.env.to_sym, :domain)}/members/email_confirmation?token=#{email_confirmation_token}"
    end

    def email_confirmed?
      !!email_verified_at
    end

    def send_confirmation_email
      KlaviyoAPI::Events.create_event(klaviyo_confirm_email_event_body)
    end

    def klaviyo_confirm_email_event_body
      {
        "data": {
          "type": "event",
          "attributes": {
            "profile": {
              "data": {
                "type": "profile",
                "attributes": {
                  "email": email,
                  "first_name": first_name,
                  "last_name": last_name,
                  "phone_number": "+#{mobile}", # 格式为 +61412345678
                }
              }
            },
            "metric": {
              "data": {
                "type": "metric",
                "attributes": {
                  "name": "Confirm Email"
                }
              }
            },
            "properties": BeansAdmin::API::Entities::KlaviyoMember.represent(self).as_json,
            "time": Time.current,
            "value":  0,
            "unique_id": SecureRandom.uuid
          }
        }
      }
    end

    def full_name
      "#{ first_name } #{ last_name }"
    end

    # https://docs.sendgrid.com/api-reference/contacts
    # 由于sendgrid提供的接口没有直接根据sendgrid_id直接修改用户邮箱，所以每次修改邮箱需要先删除旧邮箱，再添加新邮箱
    def sync_contact_to_sendgrid
      old_email = email_previous_change&.first
      # 从接收活动邮件改为不接收活动邮件，需要从sendgrid中删除
      if saved_change_to_receive_activity_email? && !receive_activity_email && email.present?
        DeleteContactsFromSendgridJob.perform_later([old_email, email].uniq.compact)
      elsif saved_change_to_email?
        # 如果是不接收活动邮件，将old_email、email从sendgrid中删除
        # 如果是接收活动邮件，将old_email从sendgrid中删除，将email添加到sendgrid中
        if receive_activity_email
          DeleteContactsFromSendgridJob.perform_later([old_email].compact)          
          AddContactsToSendgridJob.perform_later([{ email: email, first_name: first_name, last_name: last_name }]) if email.present?
        else
          DeleteContactsFromSendgridJob.perform_later([old_email, email].uniq.compact)
        end
      end
    end

    private

    def generate_invite_code
      loop do
        self.invite_code = SecureRandom.alphanumeric(INVITE_CODE_LENGTH).downcase
        break unless self.class.exists?(invite_code: invite_code)
      end
    end

    def set_names
      # NOTE: 用户姓名暂时用 User + 手机号后四位格式
      self.first_name ||= "User"
      self.last_name ||= mobile.to_s.last(4)
    end

    def format_email
      self.email = email&.strip&.downcase
    end

    def generate_confirmation_token
      loop do
        self.email_confirmation_token = SecureRandom.urlsafe_base64
        break unless self.class.exists?(email_confirmation_token: email_confirmation_token)
      end
    end

    def sign_up_reward
      create_integral_record(:sign_up, self, channel)
      inviter&.create_integral_record(:inviting, self, channel)
    end

    def suggest_reward(targetable, channel)
      create_integral_record(:suggest, targetable, channel)
    end

    def assign_newbie_coupon
      return if assigned_app_newbie_coupon
      
      # 避免发放优惠券期间方法再被调用, 先把状态变了再发券
      update_columns(assigned_app_newbie_coupon: true)

      coupon_templates = web? ? MagicBean::CouponTemplate.web_newbie(user.selected_store_id) : MagicBean::CouponTemplate.newbie(user.selected_store_id)
      if coupon_templates.present?
        transaction do
          coupon_templates.each do |template|
            template.generate_coupon_and_assign_with_notification(user_id)
          end
        end
      end
    end

    def assign_invited_coupon
      if inviter_id_previous_change[0].blank? && inviter_id_previous_change[1].present?
        coupon_templates = web? ? MagicBean::CouponTemplate.web_invited(user.selected_store_id) : MagicBean::CouponTemplate.invited(user.selected_store_id)
        if coupon_templates.present?
          transaction do
            coupon_templates.each do |template|
              template.generate_coupon_and_assign_with_notification(inviter.user_id, "invite", id)
            end
          end
        end
      end
    end

    def assign_finish_order_coupon_to_inviter(invitee_id)
      coupon_templates = web? ? MagicBean::CouponTemplate.web_finish_order_to_inviter(user.selected_store_id) : MagicBean::CouponTemplate.finish_order_to_inviter(user.selected_store_id)
      if coupon_templates.present?
        transaction do
          coupon_templates.each do |template|
            template.generate_coupon_and_assign_with_notification(user_id, "normal", invitee_id)
          end
        end
      end
    end

    def set_channel
      self.channel = "app" unless channel?
    end

    def check_birthday
      errors.add(:birthday, I18n.t("grape.members.cannot_edit_birthday")) unless can_edit_birthday
    end

    def check_user_info_finished
      user.send :check_info_finished
    end

    # 有些人一开始生日可能是乱填的，所以限制要变成是 原本已经填写过生日的，可以再次编辑保存，新填写的一但填写就不能再修改
    def set_can_edit_birthday
      return unless birthday
      update_columns(can_edit_birthday: false)
    end

    def enqueue_reward_birthday_job
      return unless birthday

      year_diff = Date.current.year - birthday.year
      
      # 避免02-29的特殊情况，这里用生日+年份差
      tmp_date = birthday + year_diff.years
      
      wait_time = if tmp_date >= Date.current
        # 生日当天早上9点发优惠券
        "#{tmp_date} 09:00".in_time_zone
      else
        # 生日已经过了，则第二年再发, 避免02-29的特殊情况，这里用生日+年份差
        "#{birthday + (year_diff + 1).years} 09:00".in_time_zone
      end

      RewardBirthdayJob.set(wait_until: wait_time).perform_later(id)
    end

    # 10澳元无门槛（提前一个月发，有效期60天）
    def reward_birthday
      template = web? ? MagicBean::CouponTemplate.web_birthday(user.selected_store_id) : MagicBean::CouponTemplate.birthday(user.selected_store_id)
      return unless template

      template.generate_coupon_and_assign_with_notification(user_id)
    end
  end
end
