# frozen_string_literal: true

class AddWebImageToQaAndGuarantees < ActiveRecord::Migration[5.2]
  def change
    add_column :qa_and_guarantees, :web_image, :string
  end
end
