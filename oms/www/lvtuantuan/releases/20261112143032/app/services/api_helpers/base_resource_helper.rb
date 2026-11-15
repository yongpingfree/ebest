# frozen_string_literal: true

module ApiHelpers
  module BaseResourceHelper
    def default_order
      "id desc"
    end

    def end_of_association_chain
      resource_class
    end

    def collection_search_sentence
      @collection = end_of_association_chain.accessible_by(current_ability).includes(includes).ransack(ransack_params)
    end

    def collection_result_sentence
      order_by = params[:order_by].split(",").map(&:strip).compact if params[:order_by].present?
      @collection =
        if order_by
          if params[:order_by].include?("item_tag_translations.name")
            # 按中文排序
            @collection.result.with_translations("zh-CN").order(params[:order_by].gsub("item_tag_translations.name", "convert_to(item_tag_translations.name, 'GBK')"))
          else
            @collection.sorts = order_by
            @collection.result.group(:id)
          end
        else
          @collection.result.order(default_order).group(:id)
        end
    end

    def collection
      # ransack.result(distinct: true) 不能处理包含列是json格式的表，所以使用group(:id)代替。group(:id) 的副作用就是拖慢了数据库查询性能
      # http://landcareweb.com/questions/11115/zai-postgresql-jsonshu-ju-lie-shang-you-suo-bu-tong
      return @collection if @collection
      collection_search_sentence
      collection_result_sentence
    end

    def resource
      @resource ||= end_of_association_chain.find_by!("#{find_by_key}" => params[find_by_key])
    end

    def find_by_key
      :id
    end

    def authorize_and_response_collection(options = {})
      authorize! :read, resource_class unless options[:skip_role_authentication]

      response_collection(options)
    end

    def response_collection(options = {})
      # 可指定使用的entity
      options = (options[:present] || {}).reverse_merge(
        with: collection_entity
      ).merge(
        options[:params] || {}
      )

      present paginate(collection), options
    end

    def authorize_and_response_resource(options = {})
      authorize! :read, resource

      response_resource(options)
    end

    def response_resource(options = {})
      options = (options[:present] || {}).reverse_merge!({
        with: "#{entity_namespace_name}::#{resource_class.name.demodulize}".constantize
      }).merge(
        options[:params] || {}
      )

      present resource, options
    end

    def authorize_and_create_resource(options = {})
      options.reverse_merge!({
        authorize: true
      })

      create_resource(options)
    end

    def create_resource(options = {})
      options.reverse_merge!({
        method: :save
      })

      build_resource
      run_member_action(:create, options, resource_params)
    end

    def authorize_and_update_resource(options = {})
      authorize_and_run_member_action(:update, options, resource_params)
    end

    def authorize_and_destroy_resource(options = {})
      authorize_and_run_member_action(:destroy, options)
    end

    def authorize_and_run_member_action(action, options = {}, *params)
      options.reverse_merge!({
        authorize: true
      })

      run_member_action(action, options, *params)
    end

    def run_member_action(action, options = {}, *params)
      options.reverse_merge!({
        present: {},
        authorize: false,
        method: action,
      })

      if options[:authorize]
        if resource.class.name == "MagicBean::Item" && resource.ae_drop_shipper
          raise CanCan::AccessDenied unless current_user.permissions.include?("ae_items")
        elsif resource.class.name == "MagicBean::Category" && resource.ae_drop_shipper
          raise CanCan::AccessDenied unless current_user.permissions.include?("ae_drop_shipper_categories")
        else
          authorize! action, resource
        end
      end

      if resource.send(options[:method], *params)
        current_admin_user.operation_records.create(operatable: resource, content: options[:log_message], store_id: current_store_id) if options[:log_message].present?
        response_resource(options[:present])
      else
        response_record_error(resource)
      end
    end

    def ransack_params
      params.select { |key, _| key.in?(ransack_keys) }.map { |key, value| [key, value.is_a?(String) ? value.strip : value] }.to_h
    end

    # 根据Ransack.predicates.keys来猜测哪些参数是查询参数
    def ransack_keys
      predicates_strings = Ransack.predicates.keys.map { |key| "_#{key}$" }.join("|")
      # 生成后的内容 /(_eq$|_eq_any$|_eq_all$|_not_eq$|_not_eq_any$|_not_eq_all$|_matches$|_matches_any$|_matches_all$|_does_not_match$|_does_not_match_any$|_does_not_match_all$|_lt$|_lt_any$|_lt_all$|_lteq$|_lteq_any$|_lteq_all$|_gt$|_gt_any$|_gt_all$|_gteq$|_gteq_any$|_gteq_all$|_in$|_in_any$|_in_all$|_not_in$|_not_in_any$|_not_in_all$|_cont$|_cont_any$|_cont_all$|_not_cont$|_not_cont_any$|_not_cont_all$|_start$|_start_any$|_start_all$|_not_start$|_not_start_any$|_not_start_all$|_end$|_end_any$|_end_all$|_not_end$|_not_end_any$|_not_end_all$|_true$|_not_true$|_false$|_not_false$|_present$|_blank$|_null$|_not_null$|_contains$|_contains_any$|_contains_all$|_starts_with$|_starts_with_any$|_starts_with_all$|_ends_with$|_ends_with_any$|_ends_with_all$|_equals$|_equals_any$|_equals_all$|_greater_than$|_greater_than_any$|_greater_than_all$|_less_than$|_less_than_any$|_less_than_all$|_gteq_datetime$|_gteq_datetime_any$|_gteq_datetime_all$|_lteq_datetime$|_lteq_datetime_any$|_lteq_datetime_all$)/
      regular_match = /(#{predicates_strings})/

      params_ransack_keys = []

      params.each do |key, _|
        if key.match?(regular_match)
          params_ransack_keys << key
        end
      end

      (params_ransack_keys + resource_class.ransackable_scopes(current_user)).uniq - except_ransack_keys
    end

    # 如果有参数符合ransack_key匹配规则但又不希望被当做ransack_key处理，可以重写该方法
    def except_ransack_keys
      []
    end

    def current_ability
      @current_ability ||= MagicBean::Ability.new(current_user)
    end
    delegate :can?, :cannot?, :authorize!, to: :current_ability

    def resource_params
      ActionController::Parameters.new(params).permit(permitted_params)
    end

    def collection_entity
      # 列表entity默认先使用Simple前缀的entity
      begin
        "#{entity_namespace_name}::Simple#{resource_class.name.demodulize}".constantize
      rescue NameError => e
        "#{entity_namespace_name}::#{resource_class.name.demodulize}".constantize
      end
    end

    def resource_class
      # request.env["REQUEST_PATH"] 返回类似/mgt/api/v1/admin_users的字符串
      "MagicBean::#{request.env["REQUEST_PATH"].split("/")[4].classify}".constantize
    end

    def permitted_params
      raise "请重写permitted_params方法"
    end

    # 如果要处理 n + 1 问题，需重写该方法
    def includes
      []
    end

    def entity_namespace_name
      raise "请重写entity_namespace_name方法"
    end

    def build_resource
      @resource = end_of_association_chain.new(resource_params)
    end

    def paginate(collection)
      collection.page(params[:page].to_i).per(params[:per_page].to_i).padding(params[:offset].to_i).tap do |data|
        header "X-Total",       data.total_count.to_s
        header "X-Total-Pages", data.total_pages.to_s
        header "X-Per-Page",    data.limit_value.to_s
        header "X-Page",        data.current_page.to_s
        header "X-Next-Page",   data.next_page.to_s
        header "X-Prev-Page",   data.prev_page.to_s
        header "X-Offset",      params[:offset].to_s
      end
    end

    def custom_paginate(collection)
      collection.tap do |data|
        header "X-Total",       data.total_count.to_s
        header "X-Total-Pages", data.total_pages.to_s
        header "X-Per-Page",    data.limit_value.to_s
        header "X-Page",        data.current_page.to_s
        header "X-Next-Page",   data.next_page.to_s
        header "X-Prev-Page",   data.prev_page.to_s
        header "X-Offset",      params[:offset].to_s
      end
    end
  end
end
