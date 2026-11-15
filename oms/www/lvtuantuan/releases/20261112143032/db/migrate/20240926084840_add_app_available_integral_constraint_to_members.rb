# frozen_string_literal: true

class AddAppAvailableIntegralConstraintToMembers < ActiveRecord::Migration[5.2]
  def up
    execute "ALTER TABLE members ADD CONSTRAINT valid_app_available_integral CHECK (app_available_integral >= 0)"
  end

  def down
    execute "ALTER TABLE members DROP CONSTRAINT valid_app_available_integral"
  end
end
