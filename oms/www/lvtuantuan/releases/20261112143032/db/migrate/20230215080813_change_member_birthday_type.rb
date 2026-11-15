# frozen_string_literal: true

class ChangeMemberBirthdayType < ActiveRecord::Migration[5.2]
  def change
    change_column :members, :birthday, :date
  end
end
