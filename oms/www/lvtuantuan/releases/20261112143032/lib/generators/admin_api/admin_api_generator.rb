# frozen_string_literal: true

class AdminApiGenerator < Rails::Generators::NamedBase
  EXCLUDE_COLUMNS = ["id", "created_at", "updated_at"].freeze

  source_root File.expand_path("templates", __dir__)

  def create_entity
    create_file "#{ api_path }/entities/#{ singular_name }.rb", <<~FILE
      # frozen_string_literal: true
      module BeansAdmin::API::Entities
        class #{ constant_name } < ::CommonEntities::Model
          #{ expose_columns }
        end
      end
    FILE
  end

  def create_api
    create_file "#{ api_path }/v1/#{ plural_name }.rb", <<~FILE
      # frozen_string_literal: true
      module BeansAdmin
        class API::V1::#{ constant_pluralize_name } < ::API

          namespace :#{ plural_name }, desc: "#{ constant_pluralize_name } API" do
            helpers do
              def permitted_params
                #{ columns.map(&:to_sym) }
              end
            end

            desc "#{ constant_pluralize_name} list", {
              success: API::Entities::#{ constant_name },
              is_array: true
            }
            paginate
            get do
              authorize_and_response_collection
            end

            desc "Create #{ singular_name }", {
              success: API::Entities::#{ constant_name }
            }
            # params do
            #   requires :name, type: String, desc: "name"
            # end
            post do
              authorize_and_create_resource
            end

            route_param :id do
              desc "#{ constant_name } detail", {
                success: API::Entities::#{ constant_name }
              }
              get do
                authorize_and_response_resource
              end

              desc "Update #{ singular_name }", {
                success: API::Entities::#{ constant_name }
              }
              # params do
              #   optional :name, type: String, desc: "name"
              # end
              put do
                authorize_and_update_resource
              end

              desc "Destroy #{ singular_name }", {
                success: API::Entities::SuccessfulResult
              }
              delete do
                authorize_and_destroy_resource
              end
            end
          end
        end
      end
    FILE
  end

  def mount_api
    inject_into_file(
      "#{ api_path }/v1.rb",
      "\n    mount BeansAdmin::API::V1::#{ constant_pluralize_name }",
      before: /\s+add_swagger_documentation/
    )
  end

  private
  def singular_name
    @singular_name ||= file_name.singularize
  end

  def plural_name
    @plural_name ||= file_name.pluralize
  end

  def constant_name
    @constant_name ||= class_name.singularize
  end

  def constant_pluralize_name
    @constant_pluralize_name ||= class_name.pluralize
  end

  def api_path
    "app/services/beans_admin/api"
  end

  def columns
    constant_name.constantize.columns.map(&:name).select { |name| !name.in?(EXCLUDE_COLUMNS) }
  end

  def expose_columns
    columns.map { |column| "expose :#{column}\n    " }.join
  end
end
