# frozen_string_literal: true

class AddStarsToComments < ActiveRecord::Migration[5.2]
  def change
    add_column :comments, :stars, :integer, default: 5, comment: "星级评分， 默认5分"
  end
end
