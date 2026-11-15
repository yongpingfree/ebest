# frozen_string_literal: true

class AddInternalReasonToAfterSales < ActiveRecord::Migration[5.2]
  def change
    add_column :after_sales, :internal_reason, :string, comment: "内部原因"
    # 责任部门
    add_column :after_sales, :department, :string, comment: "责任部门"
    # 审核说明
    add_column :after_sales, :audit_explain, :text, comment: "审核说明"
    # 审核图片，数组
    add_column :after_sales, :audit_images, :string, array: true, comment: "审核图片"
    # 审核视频
    add_column :after_sales, :audit_video, :string, comment: "审核视频"
  end
end
