# frozen_string_literal: true

module BeansAdmin::Helpers
  module OrderChannelPermissionHelper
    # Returns an array of channels that the given admin user has permission to access orders for.
    # @param [MagicBean::AdminUser] admin_user
    # @return [Array<String>]
    def calculate_order_channel_permissions(admin_user)
      channel_permissions_keys = admin_user.permissions & MagicBean::Order::CHANNEL_PERMISSION_MAPPING.keys
      MagicBean::Order::CHANNEL_PERMISSION_MAPPING.values_at(*channel_permissions_keys).flatten.uniq
    end
  end
end
