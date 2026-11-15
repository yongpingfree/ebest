# frozen_string_literal: true

class AddDeletedAtToUserHistories < ActiveRecord::Migration[5.2]
  def change
    add_column :user_histories, :deleted_at, :datetime
  end
end
