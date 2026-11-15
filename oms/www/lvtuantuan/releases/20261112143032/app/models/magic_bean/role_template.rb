# frozen_string_literal: true

class MagicBean::RoleTemplate < ApplicationRecord
  validates_presence_of :name

  has_many :admin_users, dependent: :restrict_with_error
end
