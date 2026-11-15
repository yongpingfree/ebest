# frozen_string_literal: true

module BeansApp
  class API::V1::SignInActivities < ::API
    # 签到活动 API

    namespace :sign_in_activities, desc: "签到活动 API" do
      helpers do
        def end_of_association_chain
          resource_class.active
        end

        # 计算连续签到天数
        def closest_consecutive_days(dates)
          return 0 if dates.empty?
          today = Date.today
          
          # 如果最后一天签到日期不是今天或昨天，那么连续签到天数为0
          return 0 if dates[0] != Date.yesterday && dates[0] != today
          return 1 if dates.size == 1

          closest_streak = 1
        
          dates.each_cons(2) do |first_date, last_date|
            if first_date == last_date + 1
              closest_streak += 1
            else
              break
            end
          end
        
          closest_streak
        end
      end

      before do
        # 签到不分门店，全部以墨尔本时区为准
        Time.zone = ApplicationRecord::TIME_ZONE
      end

      desc "签到活动", {
        success: API::Entities::SignInActivity
      }
      get do
        sign_in_activity = collection.first
        sign_in_dates = current_user.sign_in_histories.where(sign_in_activity: sign_in_activity).order(sign_in_date: :desc).pluck(:sign_in_date)

        consecutive_sign_in_dates = 0
        future_extra_reward_date = nil

        if sign_in_dates.present?
          # 只有连续签到才需要计算连续签到天数
          if sign_in_activity.consecutive?
            consecutive_sign_in_dates = closest_consecutive_days(sign_in_dates)

            # 如果连续签到日期为0，则从今天开始计算额外奖励日期
            if consecutive_sign_in_dates.zero?
              future_extra_reward_date = Date.current + (sign_in_activity.sign_in_times - 1).days
            else
              # 计算下一个额外奖励日期
              # 当前周期内连续签到天数
              current_consecutive_dates = consecutive_sign_in_dates % sign_in_activity.sign_in_times
              # 预计获得额外奖励日期
              future_extra_reward_date = sign_in_dates.first + (sign_in_activity.sign_in_times - current_consecutive_dates).days
            end
          else
            current_accumulative_dates = sign_in_dates.size % sign_in_activity.sign_in_times

            # 累计模式要判断最后一次签到日期是不是今天
            if sign_in_dates.first == Date.current
              future_extra_reward_date = Date.current + (sign_in_activity.sign_in_times - current_accumulative_dates).days
            else
              future_extra_reward_date = Date.current + (sign_in_activity.sign_in_times - current_accumulative_dates - 1).days
            end
          end
        elsif sign_in_activity.present?
          future_extra_reward_date = Date.current + (sign_in_activity.sign_in_times - 1).days
        end

        present :sign_in_activity, sign_in_activity, with: API::Entities::SignInActivity
        present :sign_in_dates, sign_in_dates
        present :future_extra_reward_date, future_extra_reward_date
        present :consecutive_sign_in_dates, consecutive_sign_in_dates
      end

      route_param :id do
        desc "签到", {
          success: API::Entities::SignInActivity
        }
        post "sign_in" do
          response_error I18n.t("grape.users.become_member_first") unless current_user.member
          history = resource.sign_in_histories.new(sign_in_date: Date.current, user_id: current_user.id)

          if history.save
            reward_each_time = history.reward_each_time!
            extra_reward = false
            if reward_each_time
              extra_reward = resource.extra_reward!(current_user)
            end

            { reward_each_time: reward_each_time, extra_reward: extra_reward }
          else
            response_error(I18n.t("grape.sign_in_activities.sign_in_limit"))
          end
        end
      end
    end
  end
end
