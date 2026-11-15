# frozen_string_literal: true

class AddChannelsToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :channels, :string, array: true, default: []

    say_with_time "Initialize item channels" do
      MagicBean::Item.reset_column_information

      MagicBean::Item.all.find_each do |item|
        channels = case item.channel.to_s
                   when "1"
                     ["mini_program", "app"]
                   when "2"
                     ["mini_program"]
                   when "3"
                     ["app"]
                   when "4"
                     ["web"]
                   end
        item.update_columns channels: channels
      end
    end
  end
end
