# frozen_string_literal: true

class AddChannelAndStoreIdToHistories < ActiveRecord::Migration[5.2]
  def change
    add_column :histories, :channel, :integer, default: 1
    add_belongs_to :histories, :store

    say_with_time "set default store" do
      MagicBean::History.update_all(store_id: MagicBean::Store.default.first.id)
    end
  end
end
