# frozen_string_literal: true

class CreateHomepagePagingSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :homepage_paging_settings do |t|

      t.string :name
      t.string :image
      t.belongs_to :custom_page
      t.integer :position, default: 99

      t.timestamps
    end
  end
end
