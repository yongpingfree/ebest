# frozen_string_literal: true

class TranslateFormItems < ActiveRecord::Migration[5.2]
  # 新增form_item_translations字段，分别以name/mobile/email/birthday/address/remark为前缀，以_placeholder为后缀
  def change
    add_column :form_item_translations, :name_placeholder, :string, comment: "姓名占位符"
    add_column :form_item_translations, :mobile_placeholder, :string, comment: "手机号占位符"
    add_column :form_item_translations, :email_placeholder, :string, comment: "邮箱占位符"
    add_column :form_item_translations, :birthday_placeholder, :string, comment: "生日占位符"
    add_column :form_item_translations, :address_placeholder, :string, comment: "地址占位符"
    add_column :form_item_translations, :remark_placeholder, :string, comment: "备注占位符"
  end
end
