# frozen_string_literal: true
module BeansAdmin::API::Entities
  class PagePopup < SimplePagePopup
    expose :au_suburb_ids
    expose :au_suburbs, using: BeansAdmin::API::Entities::AuSuburb
  end
end
