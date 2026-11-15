# frozen_string_literal: true

module BeansAdmin::API::Entities
  class FormItemApplication < ::CommonEntities::Model
    expose :form_item, using: MinimalFormItem
    expose :store_name
    expose :channel
    expose :apply_name
    expose :apply_email
    expose :apply_mobile
    expose :apply_birthday
    expose :apply_address
    expose :apply_remark
  end
end
