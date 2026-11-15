# frozen_string_literal: true

class ChangeItemsPositionDefault < ActiveRecord::Migration[5.2]
  def change
    change_column_default :items, :position, from: 0, to: 99999999

    say_with_time "initialize items position" do
      MagicBean::Item.update_all position: MagicBean::Item::MAX_POSITION
    end
  end
end
