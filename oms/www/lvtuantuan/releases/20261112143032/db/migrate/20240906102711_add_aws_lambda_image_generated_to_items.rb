# frozen_string_literal: true

class AddAwsLambdaImageGeneratedToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :aws_lambda_image_generated, :boolean, default: false
    add_column :stock_keeping_units, :aws_lambda_image_generated, :boolean, default: false
    add_column :brands, :aws_lambda_image_generated, :boolean, default: false
    add_column :categories, :aws_lambda_image_generated, :boolean, default: false
  end
end
