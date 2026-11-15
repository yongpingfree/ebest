# frozen_string_literal: true
module MagicBean
  class SkuSalesMailerSetting < ApplicationRecord
    # scope

    # constants
    enum send_frequency: { single: 1, daily: 2, weekly: 3 }
    enum sku_search_type: { search_by_conditions: 1, search_by_sku_ids: 2 }

    # attr related macros

    # association macros
    belongs_to :store
  
    # validation macros
    validates :title, presence: true
    validates :receiver_emails, presence: true
    validates :send_at, presence: true
    validates :deliver_after_n_days, presence: true
    validates :weekdays, presence: true, if: -> { weekly? }
    validates :sku_search_conditions, presence: true, if: -> { search_by_conditions? }
    validates :sku_ids, presence: true, if: -> { search_by_sku_ids? }

    # callback
    before_validation :reset_column_values
    after_commit :deal_with_sidekiq_job, if: -> { saved_change_to_enabled? }
  
    # other macros
    delegate :name, to: :store, prefix: true

    def skus
      sku_ids.present? ? MagicBean::StockKeepingUnit.where(id: sku_ids) : []
    end

    def can_edit_send_at?
      !enabled
    end

    private
    def reset_column_values
      self.sku_ids = [] if search_by_conditions?
      self.sku_search_conditions = {} if search_by_sku_ids?
      self.weekdays = [] unless weekly?
    end

    def deal_with_sidekiq_job
      if enabled
        enqueue_send_sku_sales_mailer_job
      else
        delete_sidekiq_job
      end
    end

    def enqueue_send_sku_sales_mailer_job
      tmp_send_at = send_at.in_time_zone
      tmp_send_at += 1.day if tmp_send_at < Time.current
      SendSkuSalesMailerJob.set(wait_until: tmp_send_at).perform_later(id)
    end

    def delete_sidekiq_job
      queue = Sidekiq::ScheduledSet.new
      queue.each do |job|
        if job.item["wrapped"] == "SendSkuSalesMailerJob" && job.item["args"][0]["arguments"] == [id]
          job.delete
        end
      end
    end
  end
end
