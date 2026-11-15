class AddFreeShippingAmountInCentByChannelToFreightTemplates < ActiveRecord::Migration[5.2]
  def change
    add_column :freight_templates, :app_free_shipping_amount_in_cent, :integer, comment: "App满金额免运费"
    add_column :freight_templates, :web_free_shipping_amount_in_cent, :integer, comment: "Web满金额免运费"
    add_column :freight_templates, :mini_program_free_shipping_amount_in_cent, :integer, comment: "小程序满金额免运费"

    say_with_time "init channel free_shipping_amount_in_cent" do
      MagicBean::FreightTemplate.reset_column_information

      MagicBean::FreightTemplate.all.each do |template|
        template.update_columns(
          app_free_shipping_amount_in_cent: template.free_shipping_amount_in_cent,
          web_free_shipping_amount_in_cent: template.free_shipping_amount_in_cent,
          mini_program_free_shipping_amount_in_cent: template.free_shipping_amount_in_cent,
        )
      end
    end
  end
end
