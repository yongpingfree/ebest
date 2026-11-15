# frozen_string_literal: true
class CreateAuSuburbFreightTemplates < ActiveRecord::Migration[5.2]
  def change
    create_table :au_suburb_freight_templates do |t|
      t.belongs_to :au_suburb
      t.belongs_to :freight_template
    end
  end
end
