# frozen_string_literal: true

class SetDefaultComponentsToCustomPages < ActiveRecord::Migration[5.2]
  def change
    change_column_default :custom_pages, :components, from: nil, to: []
  end
end
