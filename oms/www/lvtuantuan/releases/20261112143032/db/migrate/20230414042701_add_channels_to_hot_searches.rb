# frozen_string_literal: true

class AddChannelsToHotSearches < ActiveRecord::Migration[5.2]
  def change
    add_column :hot_searches, :channels, :jsonb, default: []

    say_with_time "Add default channels" do
      MagicBean::HotSearch.reset_column_information
      MagicBean::HotSearch.show.update_all(channels: ["mini_program", "app"])
    end
  end
end
