# frozen_string_literal: true

module MagicBean
  class PushMessage < ApplicationRecord
    # constants

    # concerns
    include AASM
    include AASMExtendConcern

    # attr related macros
    enum state: { draft: 0, pending: 1, pushed: 2 }
    enum kind: { service_notification: 0, promotion: 1 }

    # association macros
    belongs_to :admin_user
    belongs_to :store, optional: true
    has_many :push_message_read_logs, dependent: :destroy
    has_many :users_push_messages, dependent: :destroy

    # validation macros
    validates :title, presence: true
    validates :content, :image, presence: true, unless: :path_customized?
    validates :path_customized_type, presence: true, inclusion: { in: %w[MagicBean::Item MagicBean::CustomPage MagicBean::CustomList] }, if: :path_customized?
    validates :path_customized_id, presence: true, if: :path_customized?
    validates :push_at, presence: true, unless: :draft?
    validates :push_at, timeliness: { on_or_after: lambda { Time.current }, type: :datetime, allow_blank: true, if: -> { draft? || pending? } }

    # callbacks
    after_commit :enqueue_pushed_job , on: [:create, :update]

    # other macros
    aasm :state, column: :state, enum: true, requires_lock: true do
      state :draft, initial: true
      state :pending
      state :pushed

      event :push, after_commit: [:enqueue_push_app_notification_job] do
        transitions from: [:draft, :pending], to: :pushed
      end
    end

    ransacker :state, formatter: proc { |v| states[v] }

    # scopes

    # class methods

    # instance methods
    def read(user:, inc_views: true)
      transaction do
        increment!(:pv) if inc_views

        begin
          log = push_message_read_logs.find_or_create_by(user_id: user.id)
          if inc_views && !log.details_viewed
            log.update!(details_viewed: true)
            increment!(:uv)
          end
        rescue ActiveRecord::RecordNotUnique
          # do nothing
        end
      end

      true
    end

    def app_path
      { type: "pushMessage", params: { id: id } }.to_json
    end

    def mini_program_path
      "pages/mine/push-message/detail/index?id=#{id}&type=pushMessage"
    end

    def path_target
      @path_target = if path_customized?
                       path_customized_type.constantize.find_by(id: path_customized_id) || self
                     else
                       self
                     end
    end

    def path_target_name
      @path_name ||= path_target.title
    end

    def target_app_path
      @target_app_path ||= path_target.app_path
    end

    def target_mini_program_path
      @target_mini_program_path ||= path_target.mini_program_path
    end

    def users
      @users ||= User.includes(:member).where(id: user_ids)
    end

    protected

    def enqueue_pushed_job
      PushMessageJob.set(wait_until: push_at).perform_later(id) if can_enqueue_push_job?
    end

    def can_enqueue_push_job?
      (state_previously_changed? || push_at_previously_changed?) && pending?
    end

    def enqueue_push_app_notification_job
      push_users = (store_id? ? User.where(selected_store_id: store_id) : User.all).where(locale: user_locales)
      push_users = push_users.where(id: user_ids) if user_ids.present?
      push_user_ids = push_users.ids.uniq

      transaction do
        Sidekiq.redis do |redis|
          redis.multi do
            if store_id? || user_ids.present?
              users_push_messages = push_user_ids.inject([]) do |array, user_id|
                array << { push_message_id: id, user_id: user_id }
              end

              UsersPushMessage.import(users_push_messages)
            end

            AppNotifier.enqueue_app_push_job(title, (content || title), push_user_ids, app_link: target_app_path)
          end
        end
      end
    end
  end
end
