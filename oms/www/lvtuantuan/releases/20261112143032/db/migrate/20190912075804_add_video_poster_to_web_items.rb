# frozen_string_literal: true

class AddVideoPosterToWebItems < ActiveRecord::Migration[5.2]
  def up
    add_column :web_items, :tmp_video, :json, default: {}

    say_with_time "update web item video poster" do
      MagicBean::WebItem.reset_column_information

      MagicBean::WebItem.find_each do |item|
        item.tmp_video = { src: item.video, poster: "" }
        item.save!(validate: false)
      end
    end

    remove_column :web_items, :video

    rename_column :web_items, :tmp_video, :video
  end

  def down

    add_column :web_items, :tmp_video, :string

    say_with_time "update web item video poster" do
      MagicBean::WebItem.reset_column_information

      MagicBean::WebItem.find_each do |item|
        item.update_columns(tmp_video: item.video.dig("src"))
      end
    end

    remove_column :web_items, :video

    rename_column :web_items, :tmp_video, :video
  end
end
