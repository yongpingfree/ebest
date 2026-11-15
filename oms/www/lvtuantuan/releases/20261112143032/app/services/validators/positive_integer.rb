# frozen_string_literal: true

module Validators
  class PositiveInteger < Grape::Validations::Base
    def validate_param!(attr_name, params)
      unless (1...(1 << 31)).include?(params[attr_name])
        fail Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: "必须是正整数"
      end
    end
  end
end
