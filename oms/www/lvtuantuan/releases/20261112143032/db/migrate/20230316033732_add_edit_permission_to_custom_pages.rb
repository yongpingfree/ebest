# frozen_string_literal: true

class AddEditPermissionToCustomPages < ActiveRecord::Migration[5.2]
  def change
    add_reference :custom_pages, :creator, foreign_key: { to_table: :admin_users }
    add_column :custom_pages, :collaborator_ids, :integer, default: [], array: true

    say_with_time "Initialize creator and collaborators" do
      MagicBean::CustomPage.reset_column_information

      creator_id = Rails.env.production? ? 5 : MagicBean::AdminUser.first.id
      collaborator_ids = Rails.env.production? ? [98] : [MagicBean::AdminUser.last.id]

      MagicBean::CustomPage.all.update_all(
        creator_id: creator_id,
        collaborator_ids: collaborator_ids
      )
    end
  end
end
