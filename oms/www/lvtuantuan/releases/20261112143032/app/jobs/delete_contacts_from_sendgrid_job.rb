# frozen_string_literal: true

class DeleteContactsFromSendgridJob < ApplicationJob
  queue_as :sendgrid

  def perform(emails)
    return if emails.blank?

    # https://docs.sendgrid.com/api-reference/contacts/delete-contacts
    # 删除邮箱只提供了ids参数，需要先获取邮箱对应的sendgrid_ids，再请求删除
    search_params = { emails: emails.uniq.compact }
    response = SendGridApi.client.marketing.contacts.search.emails.post(request_body: search_params)
    if response.status_code == "200"
      sendgrid_ids = JSON.parse(response.body)["result"].map do |email, value|
        if value["contact"]
          value["contact"]["id"]
        end
      end.compact
      
      # 根据sengrid_ids删除sendgrid中的联系人
      delete_params = { ids: sendgrid_ids.join(",") }
      SendGridApi.client.marketing.contacts.delete(query_params: delete_params)
    end
  end
end
