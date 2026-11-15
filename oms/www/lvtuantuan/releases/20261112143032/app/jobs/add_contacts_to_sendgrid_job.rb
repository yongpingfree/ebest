# frozen_string_literal: true

class AddContactsToSendgridJob < ApplicationJob
  queue_as :sendgrid

  def perform(contacts)
    return if contacts.blank?

    data = {
      list_ids: [Rails.application.credentials.dig(Rails.env.to_sym, :sendgrid, :list_id)],
      contacts: contacts
    }
    
    SendGridApi.client.marketing.contacts.put(request_body: data)
  end
end
