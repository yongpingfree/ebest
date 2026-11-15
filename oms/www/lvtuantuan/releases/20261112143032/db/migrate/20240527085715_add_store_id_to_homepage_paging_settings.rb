# frozen_string_literal: true

class AddStoreIdToHomepagePagingSettings < ActiveRecord::Migration[5.2]
  def change
    add_belongs_to :homepage_paging_settings, :store
  end
end
