# frozen_string_literal: true

module MagicBean
  class AdminAssignIntegralRecord < ApplicationRecord
    attr_accessor :integral

    belongs_to :admin_user
    belongs_to :member

    validates_presence_of :content
    validates :integral, presence: true, numericality: { greater_than: 0 }

    before_create :assign_member_integral

    private

    def assign_member_integral
      member.create_integral_record(:admin_assign, nil, "app", integral)
    end
  end
end
