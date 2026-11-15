# frozen_string_literal: true

class AddRoleTemplateToAdminUsers < ActiveRecord::Migration[5.2]
  def change
    add_belongs_to :admin_users, :role_template
  end
end
