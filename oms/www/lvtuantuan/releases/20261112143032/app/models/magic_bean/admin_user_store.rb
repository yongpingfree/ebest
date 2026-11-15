# frozen_string_literal: true

class MagicBean::AdminUserStore < ApplicationRecord
  belongs_to :store
  belongs_to :admin_user
end
