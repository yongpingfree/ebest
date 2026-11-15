# frozen_string_literal: true

class AddExpressCarrierToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :express_carrier, :string, comment: "第三方邮寄派送，例如：KUAIMA"
  end
end
