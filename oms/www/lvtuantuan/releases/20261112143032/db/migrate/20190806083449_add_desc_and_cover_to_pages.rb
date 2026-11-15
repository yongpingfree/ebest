# frozen_string_literal: true

class AddDescAndCoverToPages < ActiveRecord::Migration[5.2]
  def change
    add_column :pages, :cover, :string
    add_column :pages, :desc, :string
  end
end
