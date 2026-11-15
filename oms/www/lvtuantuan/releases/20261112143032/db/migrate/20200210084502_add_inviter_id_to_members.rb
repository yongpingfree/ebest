# frozen_string_literal: true

class AddInviterIdToMembers < ActiveRecord::Migration[5.2]
  def change
    add_belongs_to :members, :inviter
    add_column :members, :invite_code, :string

    add_index :members, :invite_code, unique: true

    say_with_time "update old member's invite_code" do
      MagicBean::Member.reset_column_information
      MagicBean::Member.find_each do |member|
        member.send :generate_invite_code
        member.save!
      end
    end
  end
end
