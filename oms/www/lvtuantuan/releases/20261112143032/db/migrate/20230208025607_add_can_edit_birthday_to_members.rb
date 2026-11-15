# frozen_string_literal: true

class AddCanEditBirthdayToMembers < ActiveRecord::Migration[5.2]
  def change
    add_column :members, :can_edit_birthday, :boolean, default: true
  end
end
