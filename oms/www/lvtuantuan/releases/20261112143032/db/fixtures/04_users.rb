# frozen_string_literal: true

MagicBean::User.seed_once(:id) do |u|
  u.id = 1
  u.open_id = 1
  u.nickname = "User 1"
  u.avatar = "http://temp.im/200x200"
  u.mobile = "13800138000"
  u.gender = 1
end

MagicBean::Address.seed_once(:id) do |addr|
  addr.id = 1
  addr.user_id = 1
  addr.detail_info = "天河区华强路9号保利克洛维1110"
  addr.tel_number = "13800138000"
  addr.first_name = "小明"
  addr.last_name = "陈"
  addr.is_default = true
  addr.province_name = "广东省"
  addr.city_name = "广州市"
end
