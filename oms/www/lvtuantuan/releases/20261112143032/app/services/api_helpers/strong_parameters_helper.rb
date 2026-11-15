# frozen_string_literal: true

module ApiHelpers
  module StrongParametersHelper

    # example user parameters
    def user_params
      user = raw_parameters(params)
      user.permit(
        :origin_avatar, :origin_nickname, :origin_gender, :locale,
        member_attributes: [
          :id, :birthday, :email, :receive_activity_email, :email_verified_at, :first_name, :last_name
        ]
      )
    end

    def member_params
      member = raw_parameters(params)
      member.permit(:mobile, :email, :invite_code, :receive_activity_email, :first_name, :last_name)
    end

    def shopping_cart_item_params
      shopping_cart_item = raw_parameters(params)
      shopping_cart_item.permit(:quantity, :stock_keeping_unit_id, :source_page_name, :source_custom_list_id, :source_channel, :live_top, source_extra_hash: {})
    end

    def admin_user_params
      admin_user = raw_parameters(params)
      admin_user.permit(:name, :mobile, :role, :email, :password)
    end

    def banner_params
      banner = raw_parameters(params)
      banner.permit(:position, :image_url, :navigation_type, :appid, :path, :category)
    end

    def category_params
      category = raw_parameters(params)
      category.permit(:name, :status, :parent_id, :position)
    end

    def site_config_params
      site_config = raw_parameters(params)
      site_config.permit(:value, :description)
    end

    def address_params
      address = raw_parameters(params)
      address.permit(:province_id, :city_id, :county_id, :detail_info,
        :tel_number, :postal_code, :first_name, :last_name, :is_default)
    end

    def sku_property_params
      raw_parameters(params).permit(:text)
    end

    def sku_value_params
      raw_parameters(params).permit(:text_zh_cn)
    end

    def logistic_params
      raw_parameters(params).permit(:no, :company, :remark)
    end

    def qa_and_guarantee_params
      raw_parameters(params).permit(:title, :image)
    end

    def coupon_template_params
      raw_parameters(params).permit BeansAdmin::API::Entities::CouponTemplate.documentation.except(:id, :code).keys
    end

    def brand_params
      raw_parameters(params).permit(:name)
    end

    protected

    def raw_parameters(parameters)
      ActionController::Parameters.new(parameters)
    end
  end
end
