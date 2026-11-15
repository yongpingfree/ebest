# frozen_string_literal: true

module MagicBean
  class EventFormRecord < ApplicationRecord
    # concerns
    EVENT_FORM_RECORDS_LENGTH = {
      "collect_dragon_balls" => 1,
      "collect_slogans" => 3
    }

    DRAGON_BALLS_ANSWERS = [
      ["小米"],
      ["元气森林", "元气"],
      ["老汉口"],
      ["名创优品", "miniso"],
      ["李锦记"],
      ["ziwi"],
      ["资生堂", "shiseido"]
    ]

    # scope

    # constants

    # attr related macros
    delegate :nickname, :member_mobile, :member_id, :avatar, to: :user, prefix: true

    # association macros
    belongs_to :user
    belongs_to :event_page, counter_cache: true

    # validation macros
    validates :event_slug, presence: true
    validates :data, presence: true
    validate :event_rules

    # callbacks
    before_validation :set_event_page

    # other macros

    # instance methods

    # class methods

    # private methods

    private

    def set_event_page
      self.event_page = MagicBean::EventPage.find_by(slug: event_slug) if event_page.blank?
    end

    def event_rules
      case event_slug
      when "collect_dragon_balls"
        validate_event_form_records_length if new_record?
        validate_dragon_balls_data_keys_length
        validate_dragon_balls_answers
      when "collect_slogans"
        validate_event_form_records_length if new_record?
      end
    end

    def validate_dragon_balls_data_keys_length
      errors.add(:base, I18n.t("error.event_form_record.max_seven_dragon_balls")) if data.keys.length > 7
    end

    def validate_event_form_records_length
      errors.add(:base, I18n.t("error.event_form_record.max_records", max_records: EVENT_FORM_RECORDS_LENGTH[event_slug])) if user.event_form_records.where(event_slug: event_slug).length >= EVENT_FORM_RECORDS_LENGTH[event_slug]
    end

    # 龙珠活动答案校验
    # 1. 不能全为空
    # 2. 与标准答案匹配(忽略大小写)，含有非正确答案时不保存并提示错误行数
    # 3. 部分提交且全部正确可先保存
    # 4. 全部正确更新完成时间
    def validate_dragon_balls_answers
      data.values.map(&:strip!)
      effect_answers = data.values.reject(&:blank?)
      if effect_answers.empty?
        errors.add(:base, I18n.t("error.event_form_record.answers_cannot_be_empty"))
        return
      end

      if effect_answers.uniq.length != effect_answers.length
        errors.add(:base, I18n.t("error.event_form_record.answers_cannot_be_repeated"))
        return
      end

      wrong_line = []
      answers_index = []

      data.each do |k, v|
        next if v.blank?
        wrong_line << k unless DRAGON_BALLS_ANSWERS.select.with_index do |answers, index|
          if answers.include?(v.downcase)
            answers_index << index
            true
          end
        end.any?
      end

      if answers_index.uniq.length != answers_index.length
        errors.add(:base, I18n.t("error.event_form_record.answers_cannot_be_repeated"))
        return
      end

      if wrong_line.any?
        errors.add(:base, I18n.t("error.event_form_record.wrong_line", lines: wrong_line.join("，")))
      elsif effect_answers.length == DRAGON_BALLS_ANSWERS.length
        self.completed_at = Time.current
      else
        self.completed_at = nil
      end
    end
  end
end
