# frozen_string_literal: true

module BeansApp::API::Entities
  class Invoice < ::CommonEntities::Model
    expose :title, documentation: { type: String }
    expose :abn, documentation: { type: String }
    expose :email, documentation: { type: String }
    expose :first_name, documentation: { type: String }
    expose :last_name, documentation: { type: String }
    expose :tel_number, documentation: { type: String } do |object|
      if object.tel_number?
        object.tel_number.first(2) == "61" ? object.tel_number[2..-1] : object.tel_number
      end
    end
    expose :address, documentation: { type: String }
    expose :alias_name, documentation: { type: String }
    expose :kind, documentation: { type: String }
    expose :is_default, documentation: { type: Boolean }
  end
end
