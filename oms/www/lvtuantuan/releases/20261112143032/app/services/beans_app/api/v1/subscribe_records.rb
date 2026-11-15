# frozen_string_literal: true
module BeansApp
  class API::V1::SubscribeRecords < ::API

    namespace :subscribe_records, desc: "SubscribeRecords API" do
      helpers do
        def permitted_params
          [:targetable_id, :targetable_type, :user_id, :template_id]
        end
      end

      desc "Create SubscribeRecord", {
        success: API::Entities::SubscribeRecord
      }
      params do
        requires :all, using: API::Entities::SubscribeRecord.documentation.slice(:targetable_id, :targetable_type, :template_id)
      end
      post do
        params[:user_id] = current_user&.id
        authorize_and_create_resource
      end

      desc "Batch create SubscribeRecord", {
        success: API::Entities::SubscribeRecord,
        is_array: true
      }
      params do
        requires :all, using: API::Entities::SubscribeRecord.documentation.slice(:targetable_id, :targetable_type)
        requires :template_ids, type: Array[String], desc: "模板"
      end
      post "batch" do
        authorize! :create, MagicBean::SubscribeRecord

        records_params =
          params[:template_ids].map do |template_id|
            {
              targetable_id: params[:targetable_id],
              targetable_type: params[:targetable_type],
              user_id: current_user&.id,
              template_id: template_id
            }
          end

        records = MagicBean::SubscribeRecord.create(records_params)

        present records, with: API::Entities::SubscribeRecord
      end
    end
  end
end
